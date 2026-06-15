//+------------------------------------------------------------------+
//|                                                          CCI.mq5 |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Translated by AI"
#property link      ""
#property version   "1.00"

#include <Trade\Trade.mqh>

// --- 1. PARAMETER ---
input int    CciPeriod = 5;          // CCI Periode
input int    EmaPeriod = 50;         // Trend Filter (EMA)
input int    TpIndex = 19;           // Take Profit (Index 1-67)
input int    SlIndex = 10;           // Stop Loss (Index 1-67)
input double VolumeLots = 0.01;      // Lot-Groesse

// --- 2. INTERNE LOGIK & ARRAYS ---
CTrade         trade;
int            cci_handle;
int            ema_handle;

double         cci_buffer[];
double         ema_buffer[];
double         close_buffer[];

double         prozentWerte[68] = {
   0.0, 
   0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40, 0.45, 0.50, 
   0.55, 0.60, 0.65, 0.70, 0.75, 0.80, 0.85, 0.90, 0.95, 1.00,
   1.10, 1.20, 1.30, 1.40, 1.50, 1.60, 1.70, 1.80, 1.90, 2.00,
   2.10, 2.20, 2.30, 2.40, 2.50,
   2.75, 3.00, 3.25, 3.50, 3.75, 4.00, 4.25, 4.50, 4.75, 5.00,
   5.50, 6.00, 6.50, 7.00, 7.50, 8.00, 8.50, 9.00, 9.50, 10.0,
   11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0,
   25.0, 30.0
};

double         echterTpProzent;
double         echterSlProzent;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(1003);

   cci_handle = iCCI(_Symbol, _Period, CciPeriod, PRICE_TYPICAL);
   if(cci_handle == INVALID_HANDLE) return(INIT_FAILED);

   ema_handle = iMA(_Symbol, _Period, EmaPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(ema_handle == INVALID_HANDLE) return(INIT_FAILED);

   ArraySetAsSeries(cci_buffer, true);
   ArraySetAsSeries(ema_buffer, true);
   ArraySetAsSeries(close_buffer, true);

   int actualTpIndex = TpIndex;
   int actualSlIndex = SlIndex;

   if(StringFind(_Symbol, "BTC") < 0 && StringFind(_Symbol, "ETH") < 0 && StringFind(_Symbol, "XAU") < 0 && StringFind(_Symbol, "US30") < 0 && StringFind(_Symbol, "DAX") < 0)
     {
      if (actualTpIndex > 45) actualTpIndex = 45;
      if (actualSlIndex > 45) actualSlIndex = 45;
     }

   if(actualTpIndex < 0) actualTpIndex = 0;
   if(actualTpIndex > 67) actualTpIndex = 67;
   if(actualSlIndex < 0) actualSlIndex = 0;
   if(actualSlIndex > 67) actualSlIndex = 67;

   echterTpProzent = prozentWerte[actualTpIndex];
   echterSlProzent = prozentWerte[actualSlIndex];

   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   IndicatorRelease(cci_handle);
   IndicatorRelease(ema_handle);
  }

void OnTick()
  {
   static datetime last_time = 0;
   datetime current_time = iTime(_Symbol, _Period, 0);
   if(current_time == last_time) return;

   if(CopyBuffer(cci_handle, 0, 1, 2, cci_buffer) <= 0) return;
   if(CopyBuffer(ema_handle, 0, 1, 1, ema_buffer) <= 0) return;
   if(CopyClose(_Symbol, _Period, 1, 1, close_buffer) <= 0) return;

   last_time = current_time;

   double currentCci = cci_buffer[0];
   double prevCci = cci_buffer[1];
   double close = close_buffer[0];
   double ema = ema_buffer[0];

   bool cciBreakout = prevCci <= 100 && currentCci > 100;
   bool trendConfirmLong = close > ema;
   bool longSignal = cciBreakout && trendConfirmLong;

   bool cciBreakdown = prevCci >= -100 && currentCci < -100;
   bool trendConfirmShort = close < ema;
   bool shortSignal = cciBreakdown && trendConfirmShort;

   if (longSignal && !HasOpenPosition(POSITION_TYPE_BUY))
     {
      ClosePositionsByDirection(POSITION_TYPE_SELL);
      ExecuteOrder(ORDER_TYPE_BUY);
     }
   else if (shortSignal && !HasOpenPosition(POSITION_TYPE_SELL))
     {
      ClosePositionsByDirection(POSITION_TYPE_BUY);
      ExecuteOrder(ORDER_TYPE_SELL);
     }
  }

bool HasOpenPosition(ENUM_POSITION_TYPE type)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == 1003)
        {
         if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE) == type)
            return true;
        }
     }
   return false;
  }

void ClosePositionsByDirection(ENUM_POSITION_TYPE type)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == 1003)
        {
         if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE) == type)
           {
            trade.PositionClose(ticket);
           }
        }
     }
  }

void ExecuteOrder(ENUM_ORDER_TYPE type)
  {
   double currentPrice = (type == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double pipSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE) == 0.00001) pipSize = 0.0001;
   if(SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE) == 0.001) pipSize = 0.01;

   double tpPips = MathRound((currentPrice * (echterTpProzent / 100.0)) / pipSize);
   double slPips = MathRound((currentPrice * (echterSlProzent / 100.0)) / pipSize);

   double slPrice = 0, tpPrice = 0;

   if(type == ORDER_TYPE_BUY)
     {
      slPrice = currentPrice - (slPips * pipSize);
      tpPrice = currentPrice + (tpPips * pipSize);
      trade.Buy(VolumeLots, _Symbol, currentPrice, slPrice, tpPrice, "CCI_003");
     }
   else
     {
      slPrice = currentPrice + (slPips * pipSize);
      tpPrice = currentPrice - (tpPips * pipSize);
      trade.Sell(VolumeLots, _Symbol, currentPrice, slPrice, tpPrice, "CCI_003");
     }
  }

//+------------------------------------------------------------------+
//| Tester Functions for CSV Generation                              |
//+------------------------------------------------------------------+



string GetStrategyName() { return "CCI"; }
int GetStrategyNum() { return 0; }
void GetStrategyParameters(double &params[])
{
   ArrayResize(params, 10);
   ArrayInitialize(params, 0.0);
   params[0] = (double)CciPeriod;
   params[1] = (double)EmaPeriod;
}

#include <MetricsOutput.mqh>
