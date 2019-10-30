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
            
display F;

VARIABLES
     r(t)            Spot rates
     SumOfSquareDev  Sum of square deviations;

** Model with positive forward constraints

EQUATION
    ObjDef             Objective function definition
    PosForwardCon(t)   Equations to constraint forward rates to be positive;
    
ObjDef  ..  SumOfSquareDev =E= SUM(i, power( Price(i) - SUM(t, F(t,i) / power( (1 + r(t)) , tau(t) )) , 2));

PosForwardCon(t)$(tau(t) > 0)..  (1 + r(t))**(tau(t))  =g= (1+r(t-1))**(tau(t)-1);

OPTION SOLVEOPT = REPLACE;







MODEL Bootstrap /ObjDef,PosForwardCon/;

SOLVE Bootstrap MINIMIZING SumOfSquareDev USING NLP;
display r.l;
$exit