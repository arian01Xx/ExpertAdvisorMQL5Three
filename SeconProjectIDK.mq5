
#include <Trade\Trade.mqh>

double lots=0.1;
int takeProfit=100;
int stopLoss=100;

CTrade trade;

int OnInit(){
   
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason){

}

void OnTick(){

   //bollinger bands
   double middleBandArray[];
   double upperBandArray[];
   double lownerBandArray[];
   
   ArraySetAsSeries(middleBandArray,true);
   ArraySetAsSeries(upperBandArray,true);
   ArraySetAsSeries(lownerBandArray,true);
   
   int bollingerBands=iBands(_Symbol,PERIOD_M15,20,0,2,PRICE_CLOSE);
   
   CopyBuffer(bollingerBands,0,0,3,middleBandArray);
   CopyBuffer(bollingerBands,1,0,3,upperBandArray);
   CopyBuffer(bollingerBands,2,0,3,lownerBandArray);
   
   double middleBandA=middleBandArray[0];
   double upperBandA=upperBandArray[0];
   double lownerBandA=lownerBandArray[0];
   
   //RSI
   double RSI[];
   int Rsi=iRSI(_Symbol,PERIOD_M15,14,PRICE_CLOSE);
   ArraySetAsSeries(RSI,true); //sorting prices
   CopyBuffer(Rsi,0,0,1,RSI);
   double RSIvalue=NormalizeDouble(RSI[0],2);
   
   //trade
   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   
   ask=NormalizeDouble(ask,_Digits);
   bid=NormalizeDouble(bid,_Digits);
   
   //buying
   double tpB=ask+takeProfit*_Digits;
   double slB=ask-stopLoss*_Digits;
   
   tpB=NormalizeDouble(tpB,_Digits);
   slB=NormalizeDouble(slB,_Digits);
   
   //selling
   double tpS=bid-takeProfit*_Digits;
   double slS=bid+takeProfit*_Digits;
   
   tpS=NormalizeDouble(tpS,_Digits);
   slS=NormalizeDouble(slS,_Digits);
   
   int totalOrders=OrdersTotal();
   bool orderOpenBuy=false;
   bool orderOpenSell=false;
   
   for(int i=0; i<=totalOrders; i--){
      if(OrderSelect(i)){
        if(PositionGetString(POSITION_SYMBOL)==_Symbol){
          if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){
            orderOpenBuy=true;
          }else if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL){
            orderOpenSell=true;
          }
        }
      }
   }
   
   /*Three events:
   Uptrend: RSI value<50=buy, RSI value>70= take profit
   Downtrend: RSI value>50=short, RSI value<30=take profit
   Sideways: RSI value<30=buy, RSI value>50=take profit, RSI value>70=short, RSI value<50=take profit */
   
   trade.Buy(lots,_Symbol,ask,slB,tpB);
   trade.Sell(lots,_Symbol,bid,slS,tpS);
   
   if(RSIvalue>50){
      //RSI value>70= take profit
      double takeProfitUp=(RSIvalue>70)?0.1:0.0;
      double takeProfitUpper=ask+takeProfitUp*_Digits;
      takeProfitUpper=NormalizeDouble(takeProfitUpper,_Digits);
      
      trade.Buy(lots,_Symbol,ask,slB,takeProfitUpper);
      
   }else if(RSIvalue<50){
      //RSI value<30=take profit
      double takeProfitDown=(RSIvalue<30)?0.1:0.0;
      double takeProfitDowner=bid-takeProfitDown*_Point;
      takeProfitDowner=NormalizeDouble(takeProfitDowner,_Digits);
      
      trade.Sell(lots,_Symbol,bid,slS,takeProfitDowner);
      
   }else if(RSIvalue>25 && RSIvalue<75){
      if(RSIvalue<30){
        
        double takeProfitSideB=(RSIvalue>50)?0.1:0.0;
        double takeProfitSideerB=ask+slB*_Point;
        takeProfitSideerB=NormalizeDouble(takeProfitSideerB,_Digits);
        
        trade.Buy(lots,_Symbol,ask,slB,takeProfitSideerB);
        
      }else if(RSIvalue>70){
      
        double takeProfitSideS=(RSIvalue<50)?0.1:0.0;
        double takeProfitSideerS=bid-takeProfitSideS*_Point;
        takeProfitSideerS=NormalizeDouble(takeProfitSideerS,_Digits);
        
        trade.Sell(lots,_Symbol,bid,slS,takeProfitSideerS);
      }
   }
   
   //Stochastic   
   //80 = overBuying, 20 overSelling
   double Karray[];
   double Darray[];
   
   ArraySetAsSeries(Karray,true);
   ArraySetAsSeries(Darray,true);
   
   int StochDef=iStochastic(_Symbol,PERIOD_M15,14,3,3,MODE_SMA,STO_LOWHIGH);
   
   CopyBuffer(StochDef,0,0,3,Karray);
   CopyBuffer(StochDef,1,0,3,Darray);
   
   double KValue0=Karray[0];
   double DValue0=Darray[0];
   
   double KValue1=Karray[1];
   double DValue1=Karray[1];
   
   /*Three Scenarious
   .Uptrend strategy:
    %K, %D < 50 --> %K > %D = buy signal
    
   .Downtrend Strategy:
    %K, %D > 50 --> %K < %D =  sell signal
    
   .Sideways Strategy:
    %K, %D --> %K < %D = sell signal
      -Buy signal:
      %K, %D < 20 --> %K > %D = buy signal
      %K, %D > 80 --> %K < %D = take profit
      -Sell signal:
      %K, %D > 80 --> %K < %D = sell signal
      %K, %D < 20 --> %K > %D= take profit
   */
   
   if(KValue0<50 && DValue0<50){
   //UPTREND
     if((KValue0>DValue0) && (KValue1<DValue1)){
       trade.Buy(lots,_Symbol,ask,slB,tpB);
     }
   }else if(KValue0>50 && DValue0>50){
   //DOWNTREND
     if((KValue0<DValue0) && (KValue1>DValue1)){
       trade.Sell(lots,_Symbol,bid,slS,tpS);
     }
   }else if(RSIvalue>25 && RSIvalue<75){
    //SIDEWAYS
    //BUYING
     if(KValue0<20 && DValue0<20){
        if((KValue0>DValue0) && (KValue1<DValue1)){
           double takeProfitSideRSIUp=(KValue0>80 && DValue0>80 && KValue0<DValue0 && KValue1>DValue1)?0.1:0.0;
           double takeProfitSideerRSIUp=ask+takeProfitSideRSIUp*_Point;
           takeProfitSideerRSIUp=NormalizeDouble(takeProfitSideerRSIUp,_Digits);
           
           trade.Buy(lots,_Symbol,ask,slB,takeProfitSideerRSIUp);
        }
     }
     //SELLING
     if(KValue0>80 && DValue0>80){
       if((KValue0<DValue0) && (KValue1>DValue1)){
           double takeProfitSideRSIDown=(KValue0<20 && DValue0<20 && KValue0>DValue0 && KValue1<DValue1)?0.1:0.0;
           double takeProfitSideeRSIDown=bid-takeProfitSideRSIDown*_Point;
           takeProfitSideeRSIDown=NormalizeDouble(takeProfitSideeRSIDown,_Digits);
           
           trade.Sell(lots,_Symbol,bid,slS,takeProfitSideeRSIDown);
       }
     }
   }
   
   //bollinger Bands && RSI && stochastic
   if(ask>lownerBandA){
     if(RSIvalue<30 && KValue0<20 && DValue0<20 && KValue1>DValue1){
       trade.Buy(lots,_Symbol,ask,slB,tpB);
     }
   }else if(bid>upperBandA){
     if(RSIvalue>70 && KValue0>80 &&DValue0>80 && DValue1>KValue1){
       trade.Sell(lots,_Symbol,bid,slS,tpS);
     }
   }
}