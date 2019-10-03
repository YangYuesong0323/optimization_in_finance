$TITLE Mean-variance model.
$eolcom //

// define a set which is named as Assets, containing 8 items
SET Assets;

ALIAS(Assets,i,j);

PARAMETERS
         RiskFreeRate
         ExpectedReturns(i)  'Expected returns'
         VarCov(i,j)         'Variance-Covariance matrix' ;

* Read from Estimate.gdx the data needed to run the mean-variance model

$GDXIN Estimate
$LOAD Assets=subset RiskFreeRate=MeanRiskFreeReturn VarCov ExpectedReturns
$GDXIN


* Risk attitude: 0 is risk-neutral, 1 is very risk-averse.;

// define a scaler named lambda, (treat it as just a variable)
SCALAR
    lambda 'Risk attitude';

// define a positive variable X(i), proportional allocation of instrument i in the overall portfolio, (treat it as just a variable)
POSITIVE VARIABLES
    X(i) 'Holdings of assets'
    v    'borrowing percentage'
;

// define a few variables
VARIABLES
    PortVariance 'Portfolio variance'
    PortReturn   'Portfolio return'
    z            'Objective function value'
;
//define a few function names
EQUATIONS
    ReturnDef    'Equation defining the portfolio return'
    VarDef       'Equation defining the portfolio variance'
    NormalCon    'Equation defining the normalization contraint'
    ObjDef       'Objective function definition'
    MaxBorrow    '9 times of the initial capital'
;

// PortReturn stands for portfolio return, which is expected return of each i, sum over all i.
// sum() function here is diff from python, here means summation notation in math.
// sum(i, ) is sum over i. X(i) is defined above and expected returns is defined as well
ReturnDef ..   PortReturn    =e= sum(i,X(i)*ExpectedReturns(i)) - RiskfreeRate * v;

// portfolio variance (risk), is sum over i and j for each combination of i and j.
// sum( (i,j), ) sum over i and j
VarDef    ..   PortVariance  =e= sum((i,j),X(i)*X(j)*VarCov(i,j));

// constrain that 1) we do not allow taking long position and short position at the same time (this is what happens in real world)
//                2) invest all current cash (this is more like an assumption for the equation to be true)
NormalCon ..   SUM(i, x(i)) - v =e= 1;

// overall objective function incorporates lambda
ObjDef    ..   z             =e= (1-lambda) * PortReturn - lambda * PortVariance;

MaxBorrow ..   v  =L= 9

// define a model named MeanVar which contains 4 equations defined above
MODEL MeanVar 'PFO Model 3.2.3' /ReturnDef,VarDef,NormalCon,ObjDef,MaxBorrow/;

// when lambda is 1. Change lambda will change the final output
lambda = 0.005;

// execute solver with objective to MAXIMIZE z which is the objective function.
// nlp is just one solver. Gams has more than 25 solvers! (i thought nlp stands for natural lanaguage processing, hahahaha)
SOLVE MeanVar MAXIMIZING z USING nlp;

//simply print some results so we can visualize the solver output
// .l is level value, .lo is lower bound, .up is upper bound and .m is marginal
// I suspect/guess the reason we have a range of answers (upper and lower bound) is because
// 1) the programming tool is using simulation to find answers (maybe gradient ascent? i dont know)
// 2) there are more than 1 answers available
display x.l, v.l,PortVariance.l, PortReturn.l;

