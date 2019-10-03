$TITLE Mean-variance model.
$eolcom //

SET Assets;

ALIAS(Assets,i,j);

PARAMETERS
         ExpectedReturns(i)  'Expected returns'
         VarCov(i,j)         'Variance-Covariance matrix' ;

* Read from Estimate.gdx the data needed to run the mean-variance model

$GDXIN Estimate
$LOAD Assets=subset VarCov ExpectedReturns
$GDXIN

SCALAR
    lambda 'Risk attitude' 
;

POSITIVE VARIABLES
    X0(i) 'no cost amount'
    X1(i) 'cost amount'
;

BINARY VARIABLE
    Z(i)          'Indicator variable for assets included in the portfolio'
;

VARIABLES
    X(i)  'holdings'
    PortVariance 'Portfolio variance'
    PortReturn   'Portfolio return'
    obj            'Objective function value'
;

SCALARS
    Flatcost / 0.001 /
    Linearcost / 0.005 /
;

// Amount at which is possible to make transactions at the flat fee.
X0.up(i) = 0.2;
// Or more generally normalized as:
*x_0.UP(i) = FlatCost/PropCost;

//define a few function names
EQUATIONS
    ReturnDef    'Equation defining the portfolio return'
    VarDef       'Equation defining the portfolio variance'
    NormalCon    'Equation defining the normalization contraint'
    ObjDef       'Objective function definition'
    HoldingCon(i)   'sum up to 1'
    FlatBound(i)    'bound1'
    LinearBound(i)  'bound2'
;
    

VarDef    ..   PortVariance  =E= SUM((i,j),X(i)*X(j)*VarCov(i,j));

NormalCon ..   SUM(i, X(i))  =E= 1;

HoldingCon(i) ..  X(i) =E= X0(i) + X1(i);

FlatBound(i) ..   X0(i) =l= X0.up(i) * Z(i);

LinearBound(i) .. X1(i) =l= Z(i);

ReturnDef .. PortReturn =e= SUM(i, (ExpectedReturns(i) * X0(i) - Flatcost * Z(i)) ) +
                            SUM(i, (ExpectedReturns(i) - Linearcost) * X1(i) );

ObjDef .. obj =E= (1 - lambda) * PortReturn - lambda * PortVariance;

MODEL MeanVar /ReturnDef,VarDef,NormalCon,ObjDef,HoldingCon,FlatBound,LinearBound/;






lambda = 0.5;
option miqcp = cplex;
SOLVE MeanVar MAXIMIZING obj USING MIQCP;
display x.l, PortVariance.l, PortReturn.l;

