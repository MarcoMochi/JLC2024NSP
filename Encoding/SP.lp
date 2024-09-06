#const max_time = 119.
overlap(RID1, RID2, L1, L2) :- room(RID1, _), dur_tom(RID1,L1), x(RID2, _, _, _), room(RID2, _), dur_tom(RID2,L2), RID1 < RID2.
{order(RID1, RID2, L2)} :- overlap(RID1,RID2,_,L2).
order(RID2, RID1, L1) :- not order(RID1, RID2, _), overlap(RID1, RID2, L1, _).

start(RID, L+L0) :- room(RID, _), reg(RID, _, P), percorso(P,0,L0), dur_chair(RID, L).
start(RID, L) :- room(RID, _), reg(RID, _, P), percorso(P,0,L), not dur_chair(RID, _).
start(RID, L) :- order(RID2, RID, _), end(RID2, L).
end(RID, S+L) :- start(RID, S), dur_tom(RID, L), S < max_time.
last_end(ID,T) :- #max{Q : end(ID,Q)} = T, end(ID,_).
:- last_end(ID, T), T > max_time.
:- start(RID, S), S >= max_time.
:- start(RID, S), dur_tom(RID, L), S+L > max_time.


start_phase_0(RID, L0-1, E-LT-LC-L0) :- room(RID, _), last_end(RID, E), percorso(P,0,L0), dur_chair(RID, LC), dur_tom(RID, LT).
start_phase_0(RID, L0-1, E-LT-L0) :- room(RID, _), last_end(RID, E), percorso(P,0,L0), not dur_chair(RID, _), dur_tom(RID, LT).
start_phase_1(RID, L-1, E+L0) :- room(RID, _), start_phase_0(RID, L0, E), dur_chair(RID, L).
res_chair(RID, T..T+L) :- start_phase_1(RID, L, T).
{chair(ROOM, RID, N) : N = 1..3} = 1:- room(RID, ROOM), reg(RID,_,P), poltrone(P).
overlap_chair(RID1, RID2) :- chair(ROOM, RID1, N), chair(ROOM, RID2, N), RID1 < RID2.
:- res_chair(RID1, T), res_chair(RID2, T), overlap_chair(RID1, RID2).
res_adm(RID, T..T+L-1) :- start_phase_0(RID, L, T).
:- #count{1,R: res_adm(R, T)} > 1, res_adm(R1, T), res_adm(R2, T), R1 != R2.

timeOccupation(RID, L1+L2, P) :- reg(RID, _, P), percorso(P, 1, L1), percorso(P, 2, L2).
dur_chair(RID, L) :- timeOccupation(RID, L, P), poltrone(P).
dur_tom(RID, L) :- reg(RID, _, P), percorso(P, 3, L), poltrone(PROTOCOL).
dur_tom(RID, L0+L1) :- timeOccupation(RID, L0, PROTOCOL), percorso(PROTOCOL, 3, L1), not poltrone(PROTOCOL).

#show order/3.
#show chair/3.