$TITLE Mean-variance model with diversification constraints

* MeanVar_DivCon.gms:  Mean-variance model with diversification constraints.

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

SCALAR
     AssetMax  'Maximum number of assets allowed' /3/
     lambda    'Risk attitude';

VARIABLES
    x(i)       'Holdings of assets';


* In case short sales are allowed these bounds must be set properly.
x.LO(i) = 0.0;
x.UP(i) = 1.0;

BINARY VARIABLE
    Y(i)          'Indicator variable for assets included in the portfolio';


VARIABLES
   PortVariance   'Portfolio variance'
   PortReturn     'Portfolio return'
   z              'Objective function value'
;

EQUATIONS
    ReturnDef     'Equation defining the portfolio return'
    VarDef        'Equation defining the portfolio variance'
    NormalCon     'Equation defining the normalization contraint'
    LimitCon      'Constraint defining the maximum number of assets allowed'
    UpBounds(i)   'Upper bounds for each variable'
    LoBounds(i)   'Lower bounds for each variable'
    ObjDef        'Objective function definition'
;


ReturnDef ..   PortReturn    =E= SUM(i, ExpectedReturns(i)*x(i));

VarDef    ..   PortVariance  =E= SUM((i,j), x(i)*VarCov(i,j)*x(j));

LimitCon  ..   SUM((i),Y(i)) =l= AssetMax;

UpBounds(i)..  x(i) =l= x.UP(i)*Y(i);

LoBounds(i)..  x(i) =g= x.LO(i)*Y(i);

NormalCon ..   SUM(i, x(i))  =E= 1;

ObjDef    ..   z             =E=(1-lambda) * PortReturn - lambda * PortVariance;

MODEL MeanVarMip /ReturnDef, VarDef, LimitCon, UpBounds, LoBounds, NormalCon, ObjDef/;

OPTION  MINLP = SBB, optcr = 0;

lambda = 0.5;
SOLVE MeanVarMip MAXIMIZING z USING MINLP;
display x.l, Y.l, PortReturn.l, PortVariance.l;
