$TITLE Bootstrapping the yield curve

$eolcom //

* Bootstrap_Simple.gms:  Bootstrapping the yield curve.

SET Time Time periods /2001 * 2011/;

ALIAS (Time, t, t1, t2);

SCALARS
   Now Current year;

Now = 2001;

PARAMETER
   tau(t) Time in years;

* Note: time starts from 0

tau(t)  = ORD(t)-1;

SET
   Bonds Bonds universe
    /DS-8-06, DS-8-03, DS-7-07,
     DS-7-04, DS-6-11, DS-6-09,
     DS-6-02, DS-5-05, DS-5-03, DS-4-02/;


ALIAS(Bonds, i);

PARAMETERS
         Price(i)       Bond prices
         Coupon(i)      Coupons
         Maturity(i)    Maturities
         F(t,i)         Cashflows;

* Bond data. Prices, coupons and maturities from the Danish market

$INCLUDE "BondData.inc"

* Copy/transform data. Note division by 100 to get unit data, and
* subtraction of "Now" from Maturity date (so consistent with tau):

Price(i)    = BondData(i,"Price")/100;
Coupon(i)   = BondData(i,"Coupon")/100;
Maturity(i) = BondData(i,"Maturity") - Now;

* Calculate the ex-coupon cashflow of Bond i in year t:

F(t,i) = 1$(tau(t) = Maturity(i))
            +  coupon(i) $ (tau(t) <= Maturity(i) AND tau(t) > 0);

display F;
$exit

scalar test1, test2;

test1 = -3**(2);
test2 = power(-3,2);
display test1, test2;




VARIABLES
     r(t)            'Spot rates'
     SumOfSquareDev  'Sum of square deviations';


* Model with positive forward constraints
EQUATION
    ObjDef             'Objective function definition'
    PosForwardCon(t)   'Equations to constrain forward rates to be positive'
;


ObjDef  ..  SumOfSquareDev =E= SUM(i, power( Price(i) - SUM(t, F(t,i) / power( (1 + r(t)) , tau(t) )) , 2));

PosForwardCon(t) .. power( (1+r(t)) , tau(t) ) =g= power( (1+r(t-1)), tau(t-1));


OPTION SOLVEOPT = REPLACE;

MODEL BootstrapSimple /ObjDef,PosForwardCon/;

SOLVE BootstrapSimple MINIMIZING SumOfSquareDev USING NLP;
display r.l;


FILE TSHandle /"TermStructure.csv"/;

PUT TSHandle;

* Write the heading

PUT "spot rate";

PUT /;

LOOP(t, PUT r.l(t):6:5, PUT /);

* Close file

PUTCLOSE;
$exit


* Calculate the spot rates and discount factors

PARAMETER
   Forward(t)    One-period forward rates
   Discount(t)   Discount factors;

Forward(t) = r.l(t) $ ( tau(t) = 0 ) + ((tau(t) * r.l(t) - tau(t-1) * r.l(t-1)) / (tau(t) - tau(t-1))) $ (tau(t) > 0 );
Discount(t) = 1 / {1 + r.l(t)}**(tau(t));

display Forward, Discount;


* Also calculate the yield-to-maturity y(i) of each bond.
* This is done by solving a Constrained Nonlinear System, CNS:

POSITIVE VARIABLES
     y(i) Yield-to-Maturity of the bonds;

EQUATION
   YieldDef(i) Equations defining the yield-to-maturity;

YieldDef(i) .. Price(i) =E= SUM(t, F(t,i) / {1 + y(i)}**(tau(t)));

MODEL FindYTM /YieldDef/;

* Solve as a square system for the yields-to-maturity

SOLVE FindYTM USING CNS;
display y.l;

PARAMETERS
   PriceErrors(i)   Price errors;

PriceErrors(i) = Price(i) - SUM(t, F(t,i) / {1 + r.l(t)}**(tau(t)));

display PriceErrors;

