#program base.
0 {x(ID, D, PrID, 0) : avail(_, D)} 1 :- reg(ID, D, PrID).
{room(ID, ROOM_ID) : tomograph(_, ROOM_ID)} = 1 :- x(ID, D, _, _).
timeOccupation(ID, L1+L2, PrID) :- reg(ID, _, PrID), exam(PrID, 1, L1), exam(PrID, 2, L2).
dur(ID, L, 0) :- timeOccupation(ID, L, PrID), required_chair(PrID).
dur(ID, L, 1) :- reg(ID, _, P), exam(P, 3, L), required_chair(PrID).
dur(ID, L0+L1,1) :- timeOccupation(ID, L0, PrID), exam(PrID, 3, L1), not required_chair(PrID).
:- #sum{L, ID: dur(ID, L, 0), room(ID,ROOM_ID)} > 360, room(_, ROOM_ID).
:- #sum{L, ID: dur(ID, L, 1), room(ID,ROOM_ID)} > 120, room(_, ROOM_ID). 
:- #count{ID: room(ID, ROOM_ID), x(ID, _, X, _)} > N, limit(X, N), room(_,ROOM_ID).
:- not room(ID, ID), x(ID, D, X, _), on(X, ID).
:~ not x(ID, D,  _,0), reg(ID, D, _). [1@3, ID, D]

#show x/4.
#show required_chair/1.
#show room/2.
#show tomograph/2.
#show chair/2.
#show avail/2.
#show exam/3.
#show dur/3.
#show reg/3.
#show cost/2.
#show.



#program check(n, room, iter).
limit(n, room, iter).
:- #sum{L,P: dur(P,L,1), room(P,room)} >= n, limit(n, room, iter).

#script (python)

import os
import re
import clingo
import sys
import threading
import time
import copy
import datetime
import math

def get_text(flag=None):
    text = None
    if flag is None:
        with open("Encoding/SP.lp", "r") as reader:
            text = reader.read()
    return text

def write_tmp_file(txt1, txt2):
    with open(f"Multi/tmp.lp", "w") as writer:
        writer.write(txt1)
        writer.write("\n")
        writer.write(txt2)
    return


def main(prg):    

    
    def on_model(m):
        nonlocal model_tmp
        model_tmp = m.symbols(shown=True)
        return
    

    # get the assignment of the operations in a string format to be sent as facts for the next Time Window
    def solve(program, parts):
            program.ground(parts)
            with program.solve(on_model=handle_stop, async_=True) as hnd:
                hnd.wait(8)
                hnd.cancel()
                if not hnd.get():
                    return
                return hnd.get()

    
    def solve_subproblem(program, sp_timeout):
            program.ground()
            with program.solve(on_model=on_model, async_=True) as hnd:
                hnd.wait(sp_timeout)
                hnd.cancel()
                if not hnd.get():
                    return
                return hnd.get()

    def handle_stop(m):
            nonlocal cost
            nonlocal model
            #nonlocal timer
            nonlocal start
            if m and len(m.cost) > 0:
                cost = m.cost
                model = m.symbols(shown=True)

    def handle_model(model):
        return

    def get_model(model):
        returned_model = ""
        for atom in model:
            returned_model += atom + ".\n"
        return returned_model 
    
    def get_sub_models(models):
        found_models = ""
        for model in models:
            for atom in model:
                found_models += atom + ".\n"
        return found_models

    def get_model_room(model, room):
        returned_model = ""
        for atom in model:
            if atom.startswith("room("):
                if f",{room})" in atom: 
                    returned_model += atom + ".\n"
            else:
                returned_model += atom + ".\n"
        return returned_model 
    
    
    def get_no_good_room(model, room):
        return len([x for x in model if x.startswith("room(") and f",{room})" in x])

    def get_no_good_tomo(model, room):
        rids = [re.search("\d+", x).group(0) for x in model if x.startswith("room(") and f",{room})" in x]
        times = [int(re.findall("\d+", x)[1]) for x in model if x.startswith("dur(") and re.search("\d+", x).group(0) in rids and re.findall("\d+", x)[2] == "1"]
        return sum(times)
    
    cost = [float('inf')]
    final_delay = 100
    model = None
    model_tmp = None
    prg.configuration.solve.opt_mode = 'opt'   
    iteration = 0
    base = ("base", [])
    parts = []
    timeout = 5
    check_text = get_text()
    final_check = get_text("F")
    start = time.time()
    rooms = [1, 2]
    start = time.time()
    add_limit = 0
    while True:
        
        #timer = threading.Timer(120.0, prg.interrupt)
        print("Iteration: " + str(iteration))
        prg.cleanup()
        status = None
        if iteration == 0:
            solve(prg, [base])
        else:
            solve(prg, parts)
        print(f"RISOLTO MAIN PROBLEM CON COSTO: {cost}, CONTROLLIAMO SUB-PROBLEM")
        model = [str(x) for x in model]
        # Check if UNSAT due to tomographs
        found_unsat = False
        
        models = []
        for room in rooms:
            print("Controlliamo room " + str(room))
            ctl = clingo.Control()
            parsed_model = get_model_room(model, room)
            
            ctl.add(check_text + "\n" + parsed_model)
            ctl.ground()
            res = solve_subproblem(ctl, 3.0)
            if res.satisfiable != True:
                found_unsat = True
                print(f"Room {room} è UNSAT")
                n = get_no_good_tomo(model, room)
                print(f"Add limite {n} a stanza {room}")
                parts.append(("check", [clingo.Number(n), clingo.Number(room), clingo.Number(iteration)]))
            else:
                final_delay = sum([int(re.findall("\d+", str(x))[1]) for x in model_tmp])
        
        if found_unsat:
            iteration += 1
            continue    
        
        if not found_unsat:
            break

    time_final = time.time() -start
    print(f"Final cost {cost} with delay {final_delay} found in {time_final} seconds")
#end.