/*
D'alto Jacopo S4952059
Spinelli Sonia S5176304

Laboratorio 2 - Misure ripetute
*/

********************************************PREPARAZIONE DEL DATASET************************************************************;

LIBNAME L "/home/u62460393/MODELLI/LABO2";

PROC IMPORT OUT=L.data
	DATAFILE="/home/u62460393/MODELLI/LABO2/pulse_diet_exertype.txt" DBMS=dlm REPLACE;
	delimiter = '09'x;
	getnames=NO;
	DATAROW=2;
	RUN;

DATA L.data;
	SET L.data;
	RENAME VAR1=ID;
	RENAME VAR2=DIET;
	RENAME VAR3=EXERTYPE;
	RENAME VAR4=PULSE;
	RENAME VAR5=TIME;
	RUN;
	
PROC FORMAT;
	VALUE Tempo
		1="dopo 1 minuto"
		2="dopo 15 minuti"
		3="dopo 30 minuti";
	VALUE DIET
		1="poco grasso"
		2="grasso";
	VALUE EXERTYPE
		1="da fermo"
		2="cammimando"
		3="correndo";
 
**************************************************ANALISI DESCRITTIVA********************************************************;	

**********************************************Relazione tra PULSE e TIME*****************************************************;
	
PROC MEANS DATA=L.data n min mean max range std;
	VAR PULSE;
	RUN;

proc sort data=l.data;
		by time;
run;
	
proc means data=l.data n min mean max range std;
		var pulse;
		class time;
		format time Tempo.;
		title "Statistiche di PULSE in base ai livelli di TIME";
run;

proc sgplot data=l.data;
           vbox pulse / group=time groupdisplay=cluster;
           xaxis label="Tempo";
           format time tempo.;
           title "Boxplot di PULSE su TIME ";
           keylegend / title="tempo";
run; 



proc univariate data=l.data noprint;
  		class time;
  		var pulse;  
  		format time Tempo.;
  		histogram pulse/barfill= (time) nrows=3 odstitle="Distribuzione di PULSE al variare dei livelli di TIME.";
run;
title " ";

*****************************Relazione tra le misurazioni in tempi diversi e le variabili categoriche************************;

* punto 1: organizzazione del dataset;
proc sql; 
	create table PULSE1 as
		select ID, DIET, EXERTYPE,TIME, PULSE as PULSE1
		from L.DATA
		where TIME=1;
	create table PULSE2 as
		select ID, PULSE as PULSE2
		from L.DATA
		where TIME=2;
	create table PULSE3 as
		select ID, PULSE as PULSE3
		from L.DATA
		where TIME=3;
	create table l.data2 as
 		select ID, DIET, EXERTYPE, PULSE1, PULSE2, PULSE3
 		FROM PULSE1 NATURAL JOIN PULSE2  
 			NATURAL JOIN PULSE3;
 	create table RISPOSTA as
 		select PULSE1, PULSE2, PULSE3
 		FROM L.DATA2;
 quit;
 
***********************************per ogni pulse guardo le categoriche***********************************************;

%LET VARIABILI=diet exertype ;
%LET NUM=2;


%MACRO pulse(pulsazione);
%do i = 1 %to &num.;
    title " ";
	%LET VAR=%SCAN(&VARIABILI, &i);
	proc sort data=l.data2;
		by &var;
	run;
	proc means data=l.data2 n min mean max range std;
		var &pulsazione;
		class &var;
		format &var &VAR..;
		title "Statistiche di &pulsazione. in base ai livelli di &var.";
	run;
	proc sgplot data=l.data2 ;
           vbox &pulsazione / group=&var connect=mean;
           xaxis label="&var.";
           format &var &VAR..;
           title "Boxplot di &pulsazione. su &var. ";
           keylegend / title="&var.";
	run; 
	proc univariate data=l.data2 noprint;
  		class &var;
  		var &pulsazione;  
  		format &var &VAR..;
  		histogram &pulsazione/barfill= (&var.) nrows=3 odstitle="Distribuzione di &pulsazione. al variare dei livelli di &var.";
	run;
	ods graphics on;
	title " ";
%end;
%MEND pulse;

%pulse(pulse1);
%pulse(pulse2);
%pulse(pulse3);


********************************************MISURE RIPETUTE*************************************************;


*effetti del tempo con var espicativa exertype e diet
PROFILE;
proc glm data=l.data2 plots = (DIAGNOSTICS RESIDUALS);
  class diet exertype;
  model pulse1 pulse2 pulse3 = diet exertype/solution ;
  repeated time 3 profile/ summary printm printh printe;
run;
quit;