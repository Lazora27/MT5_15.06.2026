//+------------------------------------------------------------------+
//|                                                          ADX.mq5 |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Translated by AI"
#property link      ""
#property version   "1.00"

#include <Trade\Trade.mqh>

// --- 1. PARAMETER ---
input int    AdxPeriod = 2;          // ADX Periode
input double AdxThreshold = 10.0;    // ADX Schwellenwert
input int    TpIndex = 19;           // Take Profit (Index 1-67)
input int    SlIndex = 10;           // Stop Loss (Index 1-67)
input double VolumeLots = 0.01;      // Lot-Groesse

// --- 2. INTERNE LOGIK & ARRAYS ---
CTrade         trade;
int            adx_handle;
int            atr_handle;

double         adx_buffer[];
double         plus_di_buffer[];
double         minus_di_buffer[];
double         atr_buffer[];

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
   trade.SetExpertMagicNumber(1001);

   adx_handle = iADX(_Symbol, _Period, AdxPeriod);
   if(adx_handle == INVALID_HANDLE)
     {
      Print("Fehler beim Erstellen des ADX Indikators");
      return(INIT_FAILED);
     }

   atr_handle = iATR(_Symbol, _Period, AdxPeriod); // In C# it was using Period
   if(atr_handle == INVALID_HANDLE)
     {
      Print("Fehler beim Erstellen des ATR Indikators");
      return(INIT_FAILED);
     }

   ArraySetAsSeries(adx_buffer, true);
   ArraySetAsSeries(plus_di_buffer, true);
   ArraySetAsSeries(minus_di_buffer, true);
   ArraySetAsSeries(atr_buffer, true);

   int actualTpIndex = TpIndex;
   int actualSlIndex = SlIndex;

   // Forex Cap at 45 (5.0%) - simplifying string matching
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

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   IndicatorRelease(adx_handle);
   IndicatorRelease(atr_handle);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   // Wir arbeiten nur bei neuen Kerzen (wie OnBar in cTrader)
   static datetime last_time = 0;
   datetime current_time = iTime(_Symbol, _Period, 0);
   if(current_time == last_time) return;

   // Hole Indikator-Werte
   if(CopyBuffer(adx_handle, 0, 1, 2, adx_buffer) <= 0) return;
   if(CopyBuffer(adx_handle, 1, 1, 1, plus_di_buffer) <= 0) return;
   if(CopyBuffer(adx_handle, 2, 1, 1, minus_di_buffer) <= 0) return;
   if(CopyBuffer(atr_handle, 0, 1, 1, atr_buffer) <= 0) return;

   last_time = current_time;

   double adx = adx_buffer[0];
   double prevAdx = adx_buffer[1];
   double plusDi = plus_di_buffer[0];
   double minusDi = minus_di_buffer[0];
   double atr = atr_buffer[0];

   bool longSignal = (prevAdx <= AdxThreshold) && (adx > AdxThreshold) && (plusDi > minusDi) && (atr > 0);
   bool shortSignal = (prevAdx <= AdxThreshold) && (adx > AdxThreshold) && (minusDi > plusDi) && (atr > 0);

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

//+------------------------------------------------------------------+
//| Hilfsfunktionen                                                  |
//+------------------------------------------------------------------+
bool HasOpenPosition(ENUM_POSITION_TYPE type)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == 1001)
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
      if(PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == 1001)
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
      trade.Buy(VolumeLots, _Symbol, currentPrice, slPrice, tpPrice, "ADX_001");
     }
   else
     {
      slPrice = currentPrice + (slPips * pipSize);
      tpPrice = currentPrice - (tpPips * pipSize);
      trade.Sell(VolumeLots, _Symbol, currentPrice, slPrice, tpPrice, "ADX_001");
     }
  }

//+------------------------------------------------------------------+
//| Tester Functions for CSV Generation                              |
//+------------------------------------------------------------------+



string GetStrategyName() { return "ADX"; }
int GetStrategyNum() { return 0; }
void GetStrategyParameters(double &params[])
{
   ArrayResize(params, 10);
   ArrayInitialize(params, 0.0);
   params[0] = (double)AdxPeriod;
   params[1] = (double)AdxThreshold;
}

#include <MetricsOutput.mqh>
