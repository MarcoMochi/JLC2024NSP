#const max_time = 119.
delay(6).
overlap(ID1, ID2, L1, L2) :- room(ID1, _), dur_tom(ID1,L1), x(ID2, _, _, _), room(ID2, _), dur_tom(ID2,L2), ID1 < ID2.
{order(ID1, ID2, L2)} :- overlap(ID1,ID2,_,L2).
order(ID2, ID1, L1) :- not order(ID1, ID2, _), overlap(ID1, ID2, L1, _).
start(ID, L+L0) :- room(ID, _), reg(ID, _, PrID), exam(PrID,0,L0), dur_chair(ID, L).
start(ID, L) :- room(ID, _), reg(ID, _, PrID), exam(PrID,0,L), not dur_chair(ID, _).
start(ID, L) :- order(ID2, ID, _), end(ID2, L).
end(ID, S+L) :- start(ID, S), dur_tom(ID, L), S < max_time.
last_end(ID,T) :- #max{Q : end(ID,Q)} = T, end(ID,_), T != #inf.
:- last_end(ID, T), T > max_time.
:- start(ID, S), S >= max_time.
:- start(ID, S), dur_tom(ID, L), S+L > max_time.
start_phase_0(ID, L0-1, E-LT-LC-L0) :- room(ID, _), last_end(ID, E), exam(PrID,0,L0), dur_chair(ID, LC), dur_tom(ID, LT).
start_phase_0(ID, L0-1, E-LT-L0) :- room(ID, _), last_end(ID, E), exam(PrID,0,L0), not dur_chair(ID, _), dur_tom(ID, LT).
start_phase_1(ID, L-1, E+L0) :- room(ID, _), start_phase_0(ID, L0, E), dur_chair(ID, L).
res_chair(ID, T..T+L) :- start_phase_1(ID, L, T).
{chair(ROOM_ID, ID, N) : chair(N, ROOM_ID)} = 1:- room(ID, ROOM_ID), reg(ID,_,PrID), required_chair(PrID).
overlap_chair(ID1, ID2) :- chair(ROOM_ID, ID1, N), chair(ROOM_ID, ID2, N), ID1 < ID2.
:- res_chair(ID1, T), res_chair(ID2, T), overlap_chair(ID1, ID2).
res_adm(ID, T..T+L-1) :- start_phase_0(ID, L, T).
:- #count{1,R: res_adm(R, T)} > 1, res_adm(R1, T), res_adm(R2, T), R1 != R2.
timeOccupation(ID, L1+L2, PrID) :- reg(ID, _, PrID), exam(PrID, 1, L1), exam(PrID, 2, L2).
dur_chair(ID, L+N) :- timeOccupation(ID, L, PrID), delay(ID, N), required_chair(PrID).
dur_tom(ID, L) :- reg(ID, _, PrID), exam(PrID, 3, L), required_chair(PrID).
dur_tom(ID, L0+L1+N) :- timeOccupation(ID, L0, PrID), delay(ID, N), exam(PrID, 3, L1), not required_chair(PrID).
{delay(ID, N) : N = 1..X, delay(X)} :- room(ID, _).
:~ delay(ID, N). [N@1,ID]

#show delay/2.
