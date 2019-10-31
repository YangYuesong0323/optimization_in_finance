$TITLE Bootstrapping the yield curve

$eolcom //

SET Time Time periods /2018 * 2039/;

ALIAS (Time, t, t1, t2);

SCALARS
   Now Current year;

Now = 2018;

PARAMETER
   tau(t) Time in years;

* Note: time starts from 0
tau(t)  = ORD(t)-1;

SET
   Bonds Bonds universe
    /23-GB   ,     21-GB              ,     39-GB            ,     19-GB,
    24-GB    ,     Danske-Stat-2020   ,     Danske-Stat-2025 ,     Danske-Stat-2027/
    
ALIAS(Bonds, i);

Parameter

    Price(i)  'Bond_price'
    /23-GB 1.08485 ,   21-GB 1.10626            ,   39-GB 1.7114               ,   19-GB 1.04659  ,
    24-GB 1.424    ,   Danske-Stat-2020 1.0176  ,   Danske-Stat-2025 1.11595   ,   Danske-Stat-2027 1.0173/
    
    Coupon(i) 'Coupons'
    /23-GB 0.0150   ,    21-GB 0.0300            ,     39-GB 0.0450              ,   19-GB 0.0400 ,
    24-GB 0.0700    ,    Danske-Stat-2020 0.0025 ,     Danske-Stat-2025 0.0175   ,   Danske-Stat-2027 0.0050/
    
    Maturity(i) 'Maturities'
    /23-GB 5  ,     21-GB 3              ,     39-GB 21             ,    19-GB 1 ,
    24-GB 6   ,     Danske-Stat-2020 2   ,     Danske-Stat-2025 7   ,    Danske-Stat-2027 9/
    
    F(t,i) 'Cashflows';


* Calculate the ex-coupon cashflow of Bond i in year t:

F(t,i) = 1$(tau(t) = Maturity(i))
            +  Coupon(i) $ (tau(t) <= Maturity(i) AND tau(t) > 0);


VARIABLES
     r(t)            Spot rates
     SumOfSquareDev  Sum of square deviations;

** Model with positive forward constraints

EQUATION
    ObjDef             Objective function definition
    PosForwardCon(t)   Equations to constraint forward rates to be positive;
    
ObjDef  ..  SumOfSquareDev =E= SUM(i, power( Price(i) - SUM(t, F(t,i) / power( (1 + r(t)) , tau(t) )) , 2));

PosForwardCon(t) .. power( (1+r(t)) , tau(t) ) =g= power( (1+r(t-1)), tau(t-1));

OPTION SOLVEOPT = REPLACE;

MODEL Bootstrap /ObjDef,PosForwardCon/;

SOLVE Bootstrap MINIMIZING SumOfSquareDev USING NLP;
display r.l;

*
**---------------------------------------------------------------------*
**Now we try a variation of the bootstrap that gives a more smooth curve
**---------------------------------------------------------------------*
SCALARS
   lambda;

VARIABLES
   WeightedSumOfSquares
   ForwardRates(t)  One-period forward rates;

EQUATIONS
   WeightedObjFun
   ForwardDef(t)    Equations defining the forward rates;


WeightedObjFun..  WeightedSumOfSquares =e= lambda * SUM(i, sqr(Price(i) - SUM(t, F(t,i) / {1 + r(t)}**(tau(t)) ))) + (1-lambda) *
                                           SUM(t$(tau(t) > 0), sqr( ForwardRates(t) - ForwardRates(t-1)));

* Recall that the first forward rate, F(0,1), coincides with the one period spot rate

ForwardDef(t)..  ForwardRates(t) =E= r(t) $ ( tau(t) = 0 ) +
                                     (((1 + r(t))**(tau(t)) - (1+r(t-1))**(tau(t)-1)) / (tau(t) - tau(t-1))) $ (tau(t) > 0 );


MODEL BootstrapSmooth /WeightedObjFun,ForwardDef/;


* Output directly to an Excel file through the GDX utility
SET DifferentRuns / PP_1 * PP_10 /

ALIAS (DifferentRuns,p);

PARAMETERS
         LambdaWeight(p)          'The smoothing weight'
         YieldCurve(p,t)          'Yield curve for a given lambda'
         SummaryReport(*,*)       'Summary report'
;

* lambda has to range in the interval [0,1]
LambdaWeight(p) = (ORD(p))/(CARD(p));
DISPLAY LambdaWeight;


LOOP(p,
   lambda = LambdaWeight(p);
   SOLVE BootstrapSmooth MINIMIZING WeightedSumOfSquares USING NLP;
display lambda, forwardRates.l, r.l;
   LambdaWeight(p) = lambda;
   YieldCurve(p,t) = r.l(t);
);

SummaryReport(t,p) = YieldCurve(p,t);
SummaryReport('Lambda',p)   = LambdaWeight(p);
DISPLAY SummaryReport;

* Write SummaryReport into an Excel file

EXECUTE_UNLOAD 'Summary.gdx', SummaryReport;
EXECUTE 'gdxxrw.exe Summary.gdx O=YieldCurves.xls par=SummaryReport rng=sheet1!a1' ;
*
*