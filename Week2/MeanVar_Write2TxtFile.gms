$TITLE Mean-variance model.

SET Assets /YRS_1_3, EMU, EU_EX, PACIFIC, EMERGT, NOR_AM, CASH_EU, ITMHIST/;
ALIAS(Assets,i,j);

Parameter ExpectedReturns(i)  'Expected returns'/
YRS_1_3 0.064,    EMU     0.148,    EU_EX   0.140,    PACIFIC 0.042
EMERGT  0.238,    NOR_AM  0.187,    CASH_EU 0.094,    ITMHIST 0.097/;

Table VarCov(i,j)  'Variance-Covariance matrix'
            YRS_1_3         EMU       EU_EX     PACIFIC      EMERGT      NOR_AM
YRS_1_3       0.151      -0.099      -0.104      -0.087      -0.188      -0.154
EMU          -0.099       0.394       0.303       0.287       0.407       0.286
EU_EX        -0.104       0.303       0.328       0.285       0.359       0.268
PACIFIC      -0.087       0.287       0.285       0.807       0.464       0.260
EMERGT       -0.188       0.407       0.359       0.464       0.935       0.392
NOR_AM       -0.154       0.286       0.268       0.260       0.392       0.363
CASH_EU      -0.042       0.026       0.049       0.026       0.029       0.030
ITMHIST      -0.023       0.329       0.183       0.209       0.342       0.203
+           CASH_EU     ITMHIST

YRS_1_3      -0.042      -0.023
EMU           0.026       0.329
EU_EX         0.049       0.183
PACIFIC       0.026       0.209
EMERGT        0.029       0.342
NOR_AM        0.030       0.203
CASH_EU       0.045      -0.050
ITMHIST      -0.050       0.717
;
display i, ExpectedReturns, VarCov;

* Risk attitude: 0 is risk-neutral, 1 is very risk-averse.;
SCALAR
    lambda Risk attitude;


POSITIVE VARIABLES
    x(i) Holdings of assets;

VARIABLES
    PortVariance Portfolio variance
    PortReturn   Portfolio return
    z            Objective function value;

EQUATIONS
    ReturnDef    Equation defining the portfolio return
    VarDef       Equation defining the portfolio variance
    NormalCon    Equation defining the normalization contraint
    ObjDef       Objective function definition;


ReturnDef ..   PortReturn    =e= SUM(i, ExpectedReturns(i)*x(i));

VarDef    ..   PortVariance  =e= SUM((i,j), x(i)*VarCov(i,j)*x(j));

NormalCon ..   SUM(i, x(i))  =e= 1;

ObjDef    ..   z             =e= (1-lambda) * PortReturn - lambda * PortVariance;

MODEL MeanVar 'PFO Model 3.2.3' /ReturnDef,VarDef,NormalCon,ObjDef/;

* Define a file on the disk and associate it to the file handle FrontierHandle.
* By default, the file will be written in the current directory.

* Define a file on the disk and associate it to the file handle FrontierHandle.
* By default, the file will be written in the current directory.

FILE FrontierHandle /"MeanVarianceFrontier.csv"/;

* Just add some options to appropriately format the output.
* We will write a comma separeted value (CSV) file
* which can be easily read from any spreadsheet (see pag. 137 of the
* GAMS User's Guide).
* Also, enalarge the page width to be sure that the portfolio holdings
* fit in a row.

FrontierHandle.pc = 5;
FrontierHandle.pw = 1048;

* Assign the output stream to the file handle "Frontier"

PUT FrontierHandle;

* Write the heading

PUT "Lambda","z","Variance","ExpReturn";

LOOP (i, PUT i.tl);

PUT /;


FOR  (lambda = 0 TO 1 BY 0.1,

   SOLVE MeanVar MAXIMIZING z USING nlp;

   PUT lambda:6:5, z.l:6:5, PortVariance.l:6:5, PortReturn.l:6:5;

   LOOP (i, PUT x.l(i):6:5 );

   PUT /;
)

* Close file

PUTCLOSE;

