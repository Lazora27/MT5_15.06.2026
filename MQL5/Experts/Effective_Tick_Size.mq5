//+------------------------------------------------------------------+
//|                                     Effective_Tick_Size.mq5      |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Translated by AI"
#property link      ""
#property version   "1.00"

#include <Trade\Trade.mqh>

// --- 1. PARAMETER ---
input int    BaselinePeriod = 5;       // Baseline Periode
input double EfficiencyMultiplier = 2.0; // Effizienz Multiplikator
input int    TrendEmaPeriod = 50;      // Trend Filter (EMA)
input int    TpIndex = 19;             // Take Profit (Index 1-67)
input int    SlIndex = 10;             // Stop Loss (Index 1-67)
input double VolumeLots = 0.01;        // Lot-Groesse

// --- 2. INTERNE LOGIK & ARRAYS ---
CTrade         trade;
int            ema_handle;

double         ema_buffer[];
double         close_buffer[];
double         open_buffer[];
long           tick_volume_buffer[];

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
   trade.SetExpertMagicNumber(1010);

   ema_handle = iMA(_Symbol, _Period, TrendEmaPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(ema_handle == INVALID_HANDLE) return(INIT_FAILED);

   ArraySetAsSeries(ema_buffer, true);
   ArraySetAsSeries(close_buffer, true);
   ArraySetAsSeries(open_buffer, true);
   ArraySetAsSeries(tick_volume_buffer, true);

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
   IndicatorRelease(ema_handle);
  }

double GetTickEfficiency(int index)
  {
   double bodySize = MathAbs(close_buffer[index] - open_buffer[index]);
   long tickVol = tick_volume_buffer[index];
   if(tickVol == 0) return 0;
   return bodySize / (double)tickVol;
  }

void OnTick()
  {
   static datetime last_time = 0;
   datetime current_time = iTime(_Symbol, _Period, 0);
   if(current_time == last_time) return;

   int copy_count = BaselinePeriod + 2;
   if(CopyBuffer(ema_handle, 0, 1, 1, ema_buffer) <= 0) return;
   if(CopyClose(_Symbol, _Period, 1, copy_count, close_buffer) <= 0) return;
   if(CopyOpen(_Symbol, _Period, 1, copy_count, open_buffer) <= 0) return;
   if(CopyTickVolume(_Symbol, _Period, 1, copy_count, tick_volume_buffer) <= 0) return;

   last_time = current_time;

   double close = close_buffer[0];
   double open = open_buffer[0];
   double ema = ema_buffer[0];

   bool longSignal = false;
   bool shortSignal = false;

   // Long Signal Check
   if(close > open && close > ema)
     {
      double currentEfficiency = GetTickEfficiency(0);
      double sumEfficiency = 0;
      for(int i = 1; i <= BaselinePeriod; i++)
        {
         sumEfficiency += GetTickEfficiency(i);
        }
      double avgEfficiency = sumEfficiency / BaselinePeriod;
      if(currentEfficiency > (avgEfficiency * EfficiencyMultiplier))
        {
         longSignal = true;
        }
     }

   // Short Signal Check
   if(close < open && close < ema)
     {
      double currentEfficiency = GetTickEfficiency(0);
      double sumEfficiency = 0;
      for(int i = 1; i <= BaselinePeriod; i++)
        {
         sumEfficiency += GetTickEfficiency(i);
        }
      double avgEfficiency = sumEfficiency / BaselinePeriod;
      if(currentEfficiency > (avgEfficiency * EfficiencyMultiplier))
        {
         shortSignal = true;
        }
     }

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
      if(PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == 1010)
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
      if(PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == 1010)
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
      trade.Buy(VolumeLots, _Symbol, currentPrice, slPrice, tpPrice, "ETS_010");
     }
   else
     {
      slPrice = currentPrice + (slPips * pipSize);
      tpPrice = currentPrice - (tpPips * pipSize);
      trade.Sell(VolumeLots, _Symbol, currentPrice, slPrice, tpPrice, "ETS_010");
     }
  }

//+------------------------------------------------------------------+
//| Tester Functions for CSV Generation                              |
//+------------------------------------------------------------------+



string GetStrategyName() { return "Effective_Tick_Size"; }
int GetStrategyNum() { return 0; }
void GetStrategyParameters(double &params[])
{
   ArrayResize(params, 10);
   ArrayInitialize(params, 0.0);
   params[0] = (double)BaselinePeriod;
   params[1] = (double)EfficiencyMultiplier;
   params[2] = (double)TrendEmaPeriod;
}

#include <MetricsOutput.mqh>
