$TITLE Immunization models
$eolcom //
* Immunization.gms: Immunization models.

SET Time Time periods /2018 * 2039/

ALIAS (Time, t, t1, t2);

SCALARS
   Now      Current year
   Horizon  End of the Horizon;

Now = 2018;
Horizon = CARD(t)-1;

PARAMETER
   tau(t) Time in years;

* Note: time starts from 0

tau(t)  = ORD(t)-1;

SET
   Bonds Bonds universe
    /23-GB   ,     21-GB              ,     39-GB            ,     19-GB,
    24-GB    ,     Danske-Stat-2020   ,     Danske-Stat-2025 ,     Danske-Stat-2027/

ALIAS(Bonds, i);

PARAMETERS
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
    
    r(t) 'spot rates'
    /2020 0.033450012   ,   2021 0.033995734,    2022 0.035169666,      2023 0.036727073,       2024 0.03832141,
    2025 0.039850832    ,   2026 0.041086633,    2027 0.042167979,      2028 0.043126195,       2029 0.043980793,
    2030 0.044748048    ,   2031 0.045439426,    2032 0.046063468,      2033 0.046626849,       2034 0.047134997,
    2035 0.04759248     ,   2036 0.04800324,     2037 0.048370757,      2038 0.048698144,       2039 0.048988224/
    
    y(i) 'yield rates'
    /23-GB -0.163,  21-GB -0.446,               39-GB 0.802,             19-GB -0.679,
    24-GB -0.067,   Danske-Stat-2020 -0.627,    Danske-Stat-2025 0.107,  Danske-Stat-2027 0.308/
    
    F(t,i) 'Cashflows';

* Calculate the ex-coupon cashflow of Bond i in year t:

F(t,i) = 1$(tau(t) = Maturity(i))
            +  coupon(i) $ (tau(t) <= Maturity(i) and tau(t) > 0);


* The following are the Present value, Fischer-Weil duration (D^FW)
* and Convexity (Q_i), for both the bonds and the liabilities:


* Present value, Fisher & Weil duration, and convexity for
* the bonds.

PARAMETER
         PV(i)      Present value of assets
         Dur(i)     Duration of assets
         Conv(i)    Convexity of assets;

* Present value, Fisher & Weil duration, and convexity for
* the liability.

PARAMETER
         PV_Liab    Present value of liability
         Dur_Liab   Duration of liability
         Conv_Liab  Convexity of liability;


*PV(i)   = SUM(t, F(t,i) * exp(-r(t) * tau(t))   ); //Continuous
PV(i)   = SUM(t, F(t,i) / {1 + r(t)}**(tau(t))  ); //Discrete

*Dur(i)  = ( 1.0 / PV(i) ) * SUM(t, tau(t) * F(t,i) * exp(-r(t) * tau(t))  );  //Continuous
Dur(i)  = ( 1.0 / PV(i) ) * SUM(t, tau(t) * F(t,i) / {1 + r(t)}**(tau(t)+1)  ); //Discrete

*Dur(i)  = ( 1.0 / PV(i) ) * SUM(t, tau(t) * F(t,i) / power({1 + r(t)}, (tau(t)+1))  ); //Discrete


*Conv(i) = ( 1.0 / PV(i) ) * SUM(t, sqr(tau(t)) * F(t,i) * exp(-r(t) * tau(t)));  //Continuous
Conv(i) = ( 1.0 / PV(i) ) * SUM(t, tau(t) * (tau(t)+1) * F(t,i) / {1 + r(t)}**(tau(t)+2)  ); //Discrete

DISPLAY PV, Dur, Conv;


* Calculate the corresponding amounts for Liabilities. Use its PV as its "price".

*PV_Liab   = SUM(t, Liability(t) * exp(-r(t) * tau(t)));  //Continuous
PV_Liab   = SUM(t, Liability(t) / {1 + r(t)}**(tau(t))  ); //Discrete

*Dur_Liab  = ( 1.0 / PV_Liab ) * SUM(t, tau(t) * Liability(t) * exp(-r(t) * tau(t)));  //Continuous
*Dur_Liab  = ( 1.0 / PV_Liab ) * SUM(t, tau(t) * Liability(t) / {1 + r(t)}**(tau(t)+1)  ); //Discrete
Dur_Liab  = ( 1.0 / PV_Liab ) * SUM(t, tau(t) * Liability(t) / power({1 + r(t)},(tau(t)+1))  ); //Discrete

*Conv_Liab = ( 1.0 / PV_Liab ) * SUM(t, sqr(tau(t)) * Liability(t) * exp(-r(t) * tau(t)));  //Continuous
Conv_Liab = ( 1.0 / PV_Liab ) * SUM(t, tau(t) * (tau(t)+1) * Liability(t) / {1 + r(t)}**(tau(t)+2)  ); //Discrete

DISPLAY PV_Liab, Dur_Liab, Conv_Liab;


* Build a sequence of increasingly sophisticated immunuzation models.

POSITIVE VARIABLES
         x(i)                Holdings of bonds (amount of face value);

VARIABLE
         z                   Objective function value;

EQUATIONS
         PresentValueMatch   Equation matching the present value of asset and liability
         DurationMatch       Equation matching the duration of asset and liability
         ConvexityMatch      Equation matching the convexity of asset and liability
         ObjDef              Objective function definition;

ObjDef ..              z =E= SUM(i, Dur(i) * PV(i) * y(i) * x(i)) / (PV_Liab * Dur_Liab);

PresentValueMatch ..         SUM(i, PV(i) * x(i))               =E= PV_Liab;

DurationMatch ..             SUM(i, Dur(i)  * PV(i) * x(i))  =E= PV_Liab * Dur_Liab;

ConvexityMatch ..            SUM(i, Conv(i) * PV(i) * x(i))  =G= PV_Liab * Conv_Liab;

MODEL ImmunizationOne 'PFO Model 4.3.1' /ObjDef, PresentValueMatch, DurationMatch/;

SOLVE ImmunizationOne MAXIMIZING z USING LP;



SCALAR Convexity;

Convexity =  (1.0 / PV_Liab ) * SUM(i, Conv(i) * PV(i) * x.l(i));

DISPLAY x.l,Convexity,Conv_Liab;


MODEL ImmunizationTwo /ObjDef, PresentValueMatch, DurationMatch, ConvexityMatch/;

SOLVE ImmunizationTwo MAXIMIZING z USING LP;

DurationMatch.L = DurationMatch.L / PV_Liab;

ConvexityMatch.L = ConvexityMatch.L / PV_Liab;

DISPLAY x.l,PresentValueMatch.L,DurationMatch.L,ConvexityMatch.L;


