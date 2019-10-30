$TITLE Dedication models
$eolcom //

* Dedication.gms:  Dedication models.

SET Time 'Time periods' /2001 * 2011/;

ALIAS (Time, t, t1, t2);

SCALARS
   Now      'Current year'
   Horizon  'End of the Horizon';

Now = 2001;
Horizon = CARD(t)-1;

PARAMETER
   tau(t) 'Time in years';

* Note: time starts from 0

tau(t)  = ORD(t)-1;

SET Bonds 'Bonds universe'
    /DS-8-06, DS-8-03, DS-7-07,
     DS-7-04, DS-6-11, DS-6-09,
     DS-6-02, DS-5-05, DS-5-03, DS-4-02
/;


ALIAS(Bonds, i);

SCALAR
         spread         'Borrowing spread over the reinvestment rate';

PARAMETERS
         Price(i)       'Bond prices'
         Coupon(i)      'Coupons'
         Maturity(i)    'Maturities'
         Liability(t)   'Stream of liabilities'
         rf(t)          'Reinvestment rates'
         F(t, i)        'Cashflows'
;

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

//Data for reinvestment and borrowing
rf(t)  = 0.04;
spread = 0.02;

PARAMETER
         Liability(t) Liabilities
         /2002 =  80000, 2003 = 100000, 2004 = 110000, 2005 = 120000,
          2006 = 140000, 2007 = 120000, 2008 =  90000, 2009 =  50000,
          2010 =  75000, 2011 = 150000/;

POSITIVE VARIABLES
        x(i)           'Face value purchased'
        surplus(t)     'Amount of money reinvested'
;


VARIABLE
        v0             'Upfront investment';

EQUATION

???????


MODEL Dedication 'PFO Chapter 4' /all/;

SOLVE Dedication MINIMIZING v0 USING LP;
DISPLAY v0.l, surplus.l, x.l;

