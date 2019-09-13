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

SCALAR
    lambda Risk attitude
    risk_max Max risk when lambda is 0
    risk_min Min risk when lambda is 1
    step risk step to make risk equidistance
    Risklevel risk level at each iteration of calculation


POSITIVE VARIABLES
    x(i) Holdings of assets;

VARIABLES
    PortVariance Portfolio variance
    PortReturn   Portfolio return
    z            Objective function value
    z_equi       Objective function value for equidistance
    lambda_v     variable lambda;

EQUATIONS
    ReturnDef    Equation defining the portfolio return
    VarDef       Equation defining the portfolio variance
    NormalCon    Equation defining the normalization contraint
    ObjDef       Objective function definition
    equiObj      Objective function definition for equidistance
    fixVarCon    Equation to fix variance;


ReturnDef ..   PortReturn    =e= SUM(i, ExpectedReturns(i)*x(i));

VarDef    ..   PortVariance  =e= SUM((i,j), x(i)*VarCov(i,j)*x(j));

NormalCon ..   SUM(i, x(i))  =e= 1;

fixVarCon ..   PortVariance  =l= Risklevel;

ObjDef    ..   z             =e= (1-lambda) * PortReturn - lambda * PortVariance;


MODEL MeanVar 'PFO Model 3.2.3' /ReturnDef,VarDef,NormalCon,ObjDef/;

MODEL equidistance /ReturnDef,VarDef,NormalCon,fixVarCon/;

* get max risk by solving MeanVar model when lambda = 0, save it in risk_max
lambda = 0
SOLVE MeanVar MAXIMIZING z USING nlp;
risk_max = PortVariance.l;

* get min risk by solving MeanVar model when lambda = 1, save it in risk_min
lambda = 1
SOLVE MeanVar MAXIMIZING z USING nlp;
risk_min = PortVariance.l;

* get each step size --> equidistance

step=(risk_max-risk_min)/10;


FILE equiHandle /"equidistance.csv"/;

equiHandle.pc = 5;
equiHandle.pw = 1048;

PUT equiHandle;

* tl means title of the assets. (put yrs_1_3 instead of 0.064)
* single slash means next line, double means next next line (with a blank line in between)
PUT "Variance", "ExpReturn";
LOOP (i, PUT i.tl);
Put /;

* get PortReturn by solving equidistance model
FOR (Risklevel = risk_min to risk_max BY step,
    SOLVE equidistance MAXIMIZING PortReturn using nlp;
    PUT Risklevel:6:5, PortReturn.l:6:5;
    LOOP(i, PUT x.l(i):6:5);
    PUT /;
    )
    


* Close file

PUTCLOSE;

