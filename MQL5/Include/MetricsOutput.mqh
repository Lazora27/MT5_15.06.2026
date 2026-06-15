//+------------------------------------------------------------------+
//|                                                MetricsOutput.mqh |
//|                                      Standardized cTrader Output |
//+------------------------------------------------------------------+
#property strict

int csv_file_handle = INVALID_HANDLE;

// These functions must be implemented by the EA including this file
// void GetStrategyParameters(double &params[]);
// string GetStrategyName();
// int GetStrategyNum();

string PeriodToString(ENUM_TIMEFRAMES period)
  {
   switch(period)
     {
      case PERIOD_M1:  return "M1";
      case PERIOD_M2:  return "M2";
      case PERIOD_M3:  return "M3";
      case PERIOD_M4:  return "M4";
      case PERIOD_M5:  return "M5";
      case PERIOD_M6:  return "M6";
      case PERIOD_M10: return "M10";
      case PERIOD_M12: return "M12";
      case PERIOD_M15: return "M15";
      case PERIOD_M20: return "M20";
      case PERIOD_M30: return "M30";
      case PERIOD_H1:  return "H1";
      case PERIOD_H2:  return "H2";
      case PERIOD_H3:  return "H3";
      case PERIOD_H4:  return "H4";
      case PERIOD_H6:  return "H6";
      case PERIOD_H8:  return "H8";
      case PERIOD_H12: return "H12";
      case PERIOD_D1:  return "D1";
      case PERIOD_W1:  return "W1";
      case PERIOD_MN1: return "MN1";
      default:         return "Unknown";
     }
  }

void OnTesterInit()
  {
   string filename = GetStrategyName() + "_Results.csv";
   csv_file_handle = FileOpen(filename, FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON, ';');
   if(csv_file_handle != INVALID_HANDLE)
     {
      FileWrite(csv_file_handle, 
         "Combination_Index", "Indicator_Num", "Indicator", "Symbol", "Timeframe",
         "Para_1", "Para_2", "Para_3", "Para_4", "Para_5",
         "Para_6", "Para_7", "Para_8", "Para_9", "Para_10",
         "TP_%", "SL_%", "Spread_Pips", "Slippage_Pips", "Entry_period",
         "Total_Return", "Max_Drawdown", "Daily_Drawdown", "Win_Rate_%", "Total_Trades",
         "Winning_Trades", "Losing_Trades", "Avg_Win", "Avg_Loss", "Highest_Win",
         "Highest_Loss", "Gross_Profit", "Commission", "Net_Profit", "Profit_Factor",
         "Sharpe_Ratio", "Combinations", "Grass_Profit_Commission", "Return_DD_Ratio"
      );
     }
  }

double OnTester()
  {
   double data[39];
   ArrayInitialize(data, 0.0);
   
   data[1] = (double)GetStrategyNum();
   
   double params[];
   GetStrategyParameters(params);
   for(int i=0; i<ArraySize(params) && i<10; i++) 
     {
      data[5+i] = params[i];
     }
   
   data[15] = (double)TpIndex;
   data[16] = (double)SlIndex;
   data[17] = 0.0; // Spread_Pips
   data[18] = 0.0; // Slippage_Pips
   data[19] = 0.0; // Entry_period
   
   data[20] = TesterStatistics(STAT_PROFIT);
   data[21] = TesterStatistics(STAT_EQUITY_DD);
   data[22] = 0.0; // Daily_Drawdown
   
   double trades = TesterStatistics(STAT_TRADES);
   double wins = TesterStatistics(STAT_PROFIT_TRADES);
   double losses = TesterStatistics(STAT_LOSS_TRADES);
   double win_rate = (trades > 0) ? (wins / trades) * 100.0 : 0.0;
   
   data[23] = win_rate;
   data[24] = trades;
   data[25] = wins;
   data[26] = losses;
   
   double gross_profit = TesterStatistics(STAT_GROSS_PROFIT);
   double gross_loss = TesterStatistics(STAT_GROSS_LOSS);
   
   data[27] = (wins > 0) ? (gross_profit / wins) : 0.0;
   data[28] = (losses > 0) ? (gross_loss / losses) : 0.0;
   data[29] = TesterStatistics(STAT_MAX_PROFITTRADE);
   data[30] = TesterStatistics(STAT_MAX_LOSSTRADE);
   data[31] = gross_profit;
   data[32] = 0.0; // Commission
   data[33] = TesterStatistics(STAT_PROFIT);
   data[34] = TesterStatistics(STAT_PROFIT_FACTOR);
   data[35] = TesterStatistics(STAT_SHARPE_RATIO);
   data[36] = 0.0; // Combinations
   data[37] = gross_profit + data[32]; // Grass_Profit_Commission
   data[38] = TesterStatistics(STAT_RECOVERY_FACTOR);
   
   FrameAdd("OptResult", 1, data[20], data);
   return data[20];
  }

void OnTesterPass()
  {
   string name;
   ulong pass;
   long id;
   double value;
   double data[];
   while(FrameNext(pass, name, id, value, data))
     {
      if(name == "OptResult" && csv_file_handle != INVALID_HANDLE)
        {
         // In MT5 Tester, Symbol() in OnTesterPass returns the tested symbol if run cleanly
         string symbol_str = Symbol(); 
         string period_str = PeriodToString(Period());
         
         FileWrite(csv_file_handle, 
            (string)pass, 
            DoubleToString(data[1], 0), 
            GetStrategyName(), 
            symbol_str, 
            period_str, 
            DoubleToString(data[5], 4), DoubleToString(data[6], 4), DoubleToString(data[7], 4), DoubleToString(data[8], 4), DoubleToString(data[9], 4), 
            DoubleToString(data[10], 4), DoubleToString(data[11], 4), DoubleToString(data[12], 4), DoubleToString(data[13], 4), DoubleToString(data[14], 4), 
            DoubleToString(data[15], 2), 
            DoubleToString(data[16], 2), 
            DoubleToString(data[17], 2), 
            DoubleToString(data[18], 2), 
            DoubleToString(data[19], 2), 
            DoubleToString(data[20], 2), 
            DoubleToString(data[21], 2), 
            DoubleToString(data[22], 2), 
            DoubleToString(data[23], 2), 
            DoubleToString(data[24], 0), 
            DoubleToString(data[25], 0), 
            DoubleToString(data[26], 0), 
            DoubleToString(data[27], 2), 
            DoubleToString(data[28], 2), 
            DoubleToString(data[29], 2), 
            DoubleToString(data[30], 2), 
            DoubleToString(data[31], 2), 
            DoubleToString(data[32], 2), 
            DoubleToString(data[33], 2), 
            DoubleToString(data[34], 2), 
            DoubleToString(data[35], 2), 
            DoubleToString(data[36], 0), 
            DoubleToString(data[37], 2), 
            DoubleToString(data[38], 2)
         );
        }
     }
  }

void OnTesterDeinit()
  {
   if(csv_file_handle != INVALID_HANDLE)
     {
      FileClose(csv_file_handle);
     }
  }
