$TITLE Dedication models

* Dedication.gms:  Dedication models.

SET Time Time periods /2018 * 2039/;

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


SET
   Bonds Bonds universe
    /23-GB   ,     21-GB              ,     39-GB            ,     19-GB,
    24-GB    ,     Danske-Stat-2020   ,     Danske-Stat-2025 ,     Danske-Stat-2027/

ALIAS(Bonds, i);


SCALAR
         spread         'Borrowing spread over the reinvestment rate';

Parameters

    Price(i)  'Bond_price'
    /23-GB 1.08485 ,   21-GB 1.10626            ,   39-GB 1.7114               ,   19-GB 1.04659  ,
    24-GB 1.424    ,   Danske-Stat-2020 1.0176  ,   Danske-Stat-2025 1.11595   ,   Danske-Stat-2027 1.0173/
    
    Coupon(i) 'Coupons'
    /23-GB 0.0150   ,    21-GB 0.0300            ,     39-GB 0.0450              ,   19-GB 0.0400 ,
    24-GB 0.0700    ,    Danske-Stat-2020 0.0025 ,     Danske-Stat-2025 0.0175   ,   Danske-Stat-2027 0.0050/
    
    Maturity(i) 'Maturities'
    /23-GB 5  ,     21-GB 3              ,     39-GB 21             ,    19-GB 1 ,
    24-GB 6   ,     Danske-Stat-2020 2   ,     Danske-Stat-2025 7   ,    Danske-Stat-2027 9/
    
    Liability(t)   Stream of liabilities
    /2019 =  1000000000, 2020 = 1000000000, 2021 = 1000000000, 2022 = 1000000000, 2023 = 1000000000, 2024 = 1000000000,
    2025 =  1000000000, 2026 =  1000000000, 2027 = 1000000000, 2028 = 1000000000, 2029 = 1000000000, 2030 = 1000000000,
    2031 =  1000000000, 2032 =  1000000000, 2033 = 1000000000, 2034 = 1000000000, 2035 = 1000000000, 2036 = 1000000000,
    2037 =  1000000000, 2038 =  1000000000, 2039 = 1000000000/

    rf(t)          'Reinvestment rates'
    
    F(t, i)        'Cashflows';

* Calculate the ex-coupon cashflow of Bond i in year t:

F(t,i) = 1$(tau(t) = Maturity(i))
            +  coupon(i) $ (tau(t) <= Maturity(i) AND tau(t) > 0);

rf(t) = -0.02;
spread = 0.04;

DISPLAY F;


POSITIVE VARIABLES
        x(i)           'Face value purchased'
        surplus(t)     'Amount of money reinvested'
        borrow(t)      'Amount of money borrowed'
;


VARIABLE
        v0             'Upfront investment'
        VplusFinal     'Final value of vplus to be maximized in model 2';

SCALAR b0              'fixed budget';

EQUATION
Initial(t)             'Initialization of the investment'
Initial2(t)            'Initialization of the investment in model 2'
CashFlowCon(t)         'Equations defining the cashflow balance'
Final(t)               'Horison constraint'
FinalSurplus           'Final surplus to be maximized in model 2'
;

Initial(t)$(tau(t)=0)..      v0 =E= SUM(i, Price(i) * x(i)) + surplus(t) - borrow(t);

Initial2(t)$(tau(t)=0)..      b0 =E= SUM(i, Price(i) * x(i)) + surplus(t) - borrow(t);


CashFlowCon(t)$(tau(t)>0)..  SUM(i, F(t,i) * x(i) ) + borrow(t) + ( ( 1 + rf(t-1) ) * surplus(t-1) ) =E=
                             surplus(t) + Liability(t)  + ( 1 + rf(t-1) + spread ) * borrow(t-1);

Final(t)$(tau(t)=Horizon)..  borrow(t) =E= 0;

FinalSurplus..               VplusFinal =E= sum(t$(ord(t)=card(t)), surplus(t) );


MODEL Dedication 'PFO Model 4.2.3' /Initial, CashFlowCon, Final/;

MODEL Dedication2 /Initial2, CashFlowCon, Final, FinalSurplus/

SOLVE Dedication MINIMIZING v0 USING LP;
DISPLAY v0.l, borrow.l, surplus.l, x.l;


b0 = v0.l;

SOLVE Dedication2 MAXIMIZING VplusFinal USING LP;
DISPLAY VplusFinal.l, borrow.l, surplus.l, x.l;


