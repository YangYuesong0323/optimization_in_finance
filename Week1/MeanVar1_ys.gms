$TITLE Mean-variance model.
$eolcom //

// define a set which is named as Assets, containing 8 items
SET Assets /YRS_1_3, EMU, EU_EX, PACIFIC, EMERGT, NOR_AM, CASH_EU, ITMHIST/;

// give the Assets some alias, namely i and j. in python it is equivalent to i=Assets, j=Assets (not sure if it is shallow copy or deep copy)
ALIAS(Assets,i,j);

// define a parameter called ExpectedReturns and it is indexed based on set i. i here is optional, but including it makes debugging easier
// statistically, this is list that contains Expectation of return, i.e. E(X)
Parameter ExpectedReturns(i)  'Expected returns'/
YRS_1_3 0.064,    EMU     0.148,    EU_EX   0.140,    PACIFIC 0.042
EMERGT  0.238,    NOR_AM  0.187,    CASH_EU 0.094,    ITMHIST 0.097/;

// define a table called VarCov table and it is indexed based on set i and j. --> 2D matrix or a list of list
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

// simply print these three variables
display i, ExpectedReturns, VarCov;

* Risk attitude: 0 is risk-neutral, 1 is very risk-averse.;

// define a scaler named lambda, (treat it as just a variable)
SCALAR
    lambda 'Risk attitude';

// define a positive variable X(i), proportional allocation of instrument i in the overall portfolio, (treat it as just a variable)
POSITIVE VARIABLES
    X(i) 'Holdings of assets';

// define a few variables
VARIABLES
    PortVariance 'Portfolio variance'
    PortReturn   'Portfolio return'
    z            'Objective function value';

//define a few function names
EQUATIONS
    ReturnDef    'Equation defining the portfolio return'
    VarDef       'Equation defining the portfolio variance'
    NormalCon    'Equation defining the normalization contraint'
    ObjDef       'Objective function definition';

// PortReturn stands for portfolio return, which is expected return of each i, sum over all i.
// sum() function here is diff from python, here means summation notation in math.
// sum(i, ) is sum over i. X(i) is defined above and expected returns is defined as well
ReturnDef ..   PortReturn    =e= sum(i,X(i)*ExpectedReturns(i));

// portfolio variance (risk), is sum over i and j for each combination of i and j.
// sum( (i,j), ) sum over i and j
VarDef    ..   PortVariance  =e= sum((i,j),X(i)*X(j)*VarCov(i,j));

// constrain that 1) we do not allow taking long position and short position at the same time (this is what happens in real world)
//                2) invest all current cash (this is more like an assumption for the equation to be true)
NormalCon ..   SUM(i, x(i))  =e= 1;

// overall objective function incorporates lambda
ObjDef    ..   z             =e= (1-lambda) * PortReturn - lambda * PortVariance;

// define a model named MeanVar which contains 4 equations defined above
MODEL MeanVar 'PFO Model 3.2.3' /ReturnDef,VarDef,NormalCon,ObjDef/;

// when lambda is 1. Change lambda will change the final output
lambda = 1;

// execute solver with objective to MAXIMIZE z which is the objective function.
// nlp is just one solver. Gams has more than 25 solvers! (i thought nlp stands for natural lanaguage processing, hahahaha)
SOLVE MeanVar MAXIMIZING z USING nlp;

//simply print some results so we can visualize the solver output
// .l is level value, .lo is lower bound, .up is upper bound and .m is marginal
// I suspect/guess the reason we have a range of answers (upper and lower bound) is because
// 1) the programming tool is using simulation to find answers (maybe gradient ascent? i dont know)
// 2) there are more than 1 answers available
display x.l, PortVariance.l, PortReturn.l;

