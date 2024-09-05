%% Assegna un orario di ammissione a tutti
0 {x(RID, DAY, TS, PROTOCOL, 0) : mss(DAY, TS)} 1 :- reg(RID, DAY, PROTOCOL).
%%{x(RID, DAY, START, PROTOCOL, 1) : mss(DAY, START), START >= TS + ESAME} = 1 :- x(RID, DAY, TS, PROTOCOL, 0), percorso(PROTOCOL, 0, ESAME).
{x(RID, DAY, START, PROTOCOL, N+1) : mss(DAY,START), START = TS+ESAME} = 1 :- x(RID, DAY, TS, PROTOCOL, N), percorso(PROTOCOL, N, ESAME), N >= 0, N < 3.
:- x(RID, _, TS, PROTOCOL, 3), percorso(PROTOCOL, 3, ESAME), TS + ESAME >= 120.
%% Ci deve essere un paziente con biodistribuzione durante inizio brain dinamico
%% Limite due pazienti al massimo in anamnesi
:- #count{RID: timeAnamnesi(RID, TS)} > 2, mss(DAY,TS).
timeAnamnesi(RID, TS..TS+ESAME-1) :- x(RID, DAY, TS, PROTOCOL, 0), percorso(PROTOCOL, 0, ESAME).
%% Assegna atomo res per ogni TS in cui viene occupata una poltrona dai pazienti che la richiedono 
%% e il tempo di occupazione richiesto di un tomografo per chi fa tutto sul tomografo
timeOccupation(RID, DAY, TS, END, PROTOCOL) :- x(RID, DAY, TS, PROTOCOL, 1), x(RID, DAY, END, PROTOCOL, 3).
res(RID, DAY, TS..END-1,0) :- timeOccupation(RID, DAY, TS, END, PROTOCOL), poltrone(PROTOCOL).
res(RID, DAY, TS..TS+ESAME-1,1) :- x(RID, DAY, TS, PROTOCOL, 3), percorso(PROTOCOL, 3, ESAME), poltrone(PROTOCOL).
res(RID, DAY, TS..END+ESAME-1,1) :- timeOccupation(RID, DAY, TS, END, PROTOCOL), percorso(PROTOCOL, 3, ESAME), not poltrone(PROTOCOL).

%% Vincoli su protocolli
% Al massimo N pazienti con protocollo x per ogni tomografo (Unsat se input con più di N*2 protocolli X)
:- #count{RID: tomografo(ID, RID, DAY), x(RID, DAY, _, X, _)} > N, limit(X, N), tomografo(ID,_).
% Protocollo X su tomografo ID
:- not tomografo(ID, RID, DAY), x(RID, DAY, _, X, _), on(X, ID).
% Se X su tomografo allora non può esserci Y - preprocessing
%on(Y,ID2) :- tomografo(ID, RID, DAY), x(RID, DAY, _, X, _), X = (813;814), Y = (820;825;829), tomografo(ID2,_), ID != ID2.
%on(Y,ID2) :- tomografo(ID, RID, DAY), x(RID, DAY, _, X, _), X = (816;817;818;819;820), Y = (820;825;829), tomografo(ID2,_), ID != ID2.


%% Assegna una poltrona a chi la richiede e il tomografo a tutti
%%Crea atomo Res per ogni TS in cui è richiesta la poltrona o il tomografo
1 {chair(ID, RID, DAY) : chair(ID, _)} 1 :- x(RID, DAY, _, PROTOCOL, _), poltrone(PROTOCOL).
1 {tomografo(ID, RID, DAY) : tomografo(ID, _)} 1 :- x(RID, DAY, _, PROTOCOL, _).
%% Chi passa da poltrona a tomografo deve rimanere nella stessa stanza
:- chair(SEDIA, RID, DAY), tomografo(TOMOGRAFO, RID, DAY), chair(SEDIA, ID1), tomografo(TOMOGRAFO, ID2), ID1 != ID2.
chair(ID, RID, DAY, TS) :- chair(ID, RID, DAY), res(RID, DAY, TS, 0).
tomografo(ID, RID, DAY, TS) :- tomografo(ID, RID, DAY), res(RID, DAY, TS, 1).
%% Un solo paziente per ogni sedia
:- #count{RID : chair(ID, RID, DAY, TS)} > 1, chair(ID,_), mss(DAY, TS).
:- #count{RID: tomografo(ID, RID, DAY, TS)} > 1, tomografo(ID,_), mss(DAY, TS).
%% Assegna tutti i pazienti
:~ not x(RID, DAY, _, _,0), reg(RID, DAY, _). [1@3, RID, DAY]
%:~ x(RID, _, START, PROTOCOL, 0), x(RID, _, END, _, 3), cost(PROTOCOL, TOT), END - START - TOT >= 0. [END - START - TOT@2, RID]
#show x/5.
#show.