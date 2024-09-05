#program base.
%% Assign a patient and a room
0 {x(RID, DAY, PROTOCOL, 0) : mss(DAY, _)} 1 :- reg(RID, DAY, PROTOCOL).
{room(RID, ROOM_ID) : tomografo(_, ROOM_ID)} = 1 :- x(RID, DAY, _, _).

%% Tempo occupazione tomografo e sedie
timeOccupation(RID, L1+L2, P) :- reg(RID, _, P), percorso(P, 1, L1), percorso(P, 2, L2).
dur(RID, L, 0) :- timeOccupation(RID, L, P), poltrone(P).
dur(RID, L, 1) :- reg(RID, _, P), percorso(P, 3, L), poltrone(PROTOCOL).
dur(RID, L0+L1,1) :- timeOccupation(RID, L0, PROTOCOL), percorso(PROTOCOL, 3, L1), not poltrone(PROTOCOL).

%% Upper limit da limare successivamente.
:- #sum{L, RID: dur(RID, L, 0), room(RID,ROOM_ID)} > 360, room(_, ROOM_ID).
:- #sum{L, RID: dur(RID, L, 1), room(RID,ROOM_ID)} > 120, room(_, ROOM_ID). 

%% Vincoli su protocolli
% Al massimo N pazienti con protocollo x per ogni tomografo (Unsat se input con più di N*2 protocolli X)
:- #count{RID: room(RID, ROOM_ID), x(RID, _, X, _)} > N, limit(X, N), room(_,ROOM_ID).
:- not room(RID, ID), x(RID, DAY, X, _), on(X, ID).

:~ not x(RID, DAY,  _,0), reg(RID, DAY, _). [1@3, RID, DAY]

#show x/4.
#show poltrone/1.
#show room/2.
#show tomografo/2.
#show chair/2.
#show mss/2.
#show percorso/3.
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
        with open("Multi/app_check.lp", "r") as reader:
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
        return
    

    # get the assignment of the operations in a string format to be sent as facts for the next Time Window
    def solve(program, parts):
            program.ground(parts)
            with program.solve(on_model=handle_stop, async_=True) as hnd:
                hnd.wait(5)
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
    model = None
    model_tmp = None
    prg.configuration.solve.opt_mode = 'opt'   
    iteration = 0
    base = ("base", [])
    parts = []
    timeout = 10
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
        
        if found_unsat:
            iteration += 1
            continue    
        
        if not found_unsat:
            break

    time_final = time.time() -start
    print(f"Final cost {cost} found in {time_final} seconds")
#end.