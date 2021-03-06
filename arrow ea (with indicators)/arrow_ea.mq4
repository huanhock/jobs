//+------------------------------------------------------------------+
//|                                                  suzuki_seta.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property version   "1.00"
#property strict

extern int QntSetas=2;
extern int TipOperacoes=1; // 1-Opererar Forex   |   2-Operar OB
extern double TamanhoLote=0.01, StopLoss=600, TakeProfit=600;
extern int Slippage=0;
extern bool AtivarMartingale=false;
extern double MultiplicarGales=2.0;
extern bool AtivarMaxGales=false;
extern double MaxGales=0.16;
extern bool AtivarTraillingStop=false;
extern int TS=25;
extern int Expert_ID = 1234; 
extern string Separador1="------------Opções Binarias------------";
extern double Aposta=1; 
extern int TempoExpiracaoMinutos=1;
extern bool AtivarMartingale_OB=false;
extern double MultiplicarGales_OB=2.0;
extern bool AtivarMaxGales_OB=false;
extern double MaxGales_OB=4; 

int seta_up=0, seta_down=0, ticket, w, _MagicNumber=0;
double LoteMartingale=TamanhoLote, ApostaMG=Aposta, pip;
datetime TempoAtual;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
    int Period_ID = 0;
    switch ( Period() )
    {
        case PERIOD_MN1: Period_ID = 9; break;
        case PERIOD_W1:  Period_ID = 8; break;
        case PERIOD_D1:  Period_ID = 7; break;
        case PERIOD_H4:  Period_ID = 6; break;
        case PERIOD_H1:  Period_ID = 5; break;
        case PERIOD_M30: Period_ID = 4; break;
        case PERIOD_M15: Period_ID = 3; break;
        case PERIOD_M5:  Period_ID = 2; break;
        case PERIOD_M1:  Period_ID = 1; break;
    }
    _MagicNumber = Expert_ID * (10 + Period_ID);
    
    TempoExpiracaoMinutos=TempoExpiracaoMinutos*60;
//---
   return(INIT_SUCCEEDED);
  }
  
int start()
  {
      double UP_arrow1 = iCustom(NULL,0,"Arrow-Y",0,1);
      double DOWN_arrow1 = iCustom(NULL,0,"Arrow-Y",1,1);
      double UP_arrow2 = iCustom(NULL,0,"Arrow-X",0,1);
      double DOWN_arrow2 = iCustom(NULL,0,"Arrow-X",1,1);
      
      if(AtivarMartingale==true){ Martingale(); }
      if(AtivarMartingale_OB==true){ MartingaleOB(); }
      if(AtivarTraillingStop==true){ Trailling(); }
      
      if(TempoAtual!=Time[0]){
         if(UP_arrow1!=EMPTY_VALUE || UP_arrow2!=EMPTY_VALUE){ seta_up++; seta_down=0; }
         if(DOWN_arrow1!=EMPTY_VALUE || DOWN_arrow2!=EMPTY_VALUE){ seta_down++; seta_up=0; } 
         
         TempoAtual=Time[0];
      }
      
      if(OrdersTotal()==0){
      
      if(seta_up>=QntSetas)
         {
            seta_up=0;
            if(TipOperacoes==1){
               ticket=OrderSend(Symbol(),OP_BUY,LoteMartingale,Ask,Slippage,Ask-StopLoss*Point,Ask+TakeProfit*Point,"",_MagicNumber,0,clrBlue);
            }
            
            if(TipOperacoes==2){
               ticket=OrderSend(Symbol(),OP_BUY,ApostaMG,Ask,0,0,0,"BO exp:"+IntegerToString(TempoExpiracaoMinutos),_MagicNumber,0,clrBlue);
            }
         }
         
      if(seta_down>=QntSetas)
         {
            seta_down=0;
            if(TipOperacoes==1){
               ticket=OrderSend(Symbol(),OP_SELL,LoteMartingale,Bid,Slippage,Bid+StopLoss*Point,Bid-TakeProfit*Point,"",_MagicNumber,0,clrRed);
            }
            
            if(TipOperacoes==2){
               ticket=OrderSend(Symbol(),OP_SELL,ApostaMG,Bid,0,0,0,"BO exp:"+IntegerToString(TempoExpiracaoMinutos),_MagicNumber,0,clrRed);
            }
         }
      }
         
      return(0);
  }
  
  void Martingale(){
      {
         for(int v=0; v<=OrdersHistoryTotal(); v++){   
            if(OrderSelect(v,SELECT_BY_POS,MODE_HISTORY) && OrderSymbol()==Symbol() && OrderMagicNumber()==_MagicNumber){
                if(OrderProfit()<0){
                   LoteMartingale=LoteMartingale*MultiplicarGales;
               }else if(OrderProfit()==0){
                   LoteMartingale=OrderLots();
               }else if(OrderProfit()>0){
                   LoteMartingale=TamanhoLote;
               }
            }
         }
     
         if(AtivarMaxGales==true && LoteMartingale>MaxGales)
            {
               LoteMartingale=TamanhoLote;
            }   
      }
  }
  
  void MartingaleOB()
  {
      for(int i=0; i<=OrdersHistoryTotal(); i++){    
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)&&TipOperacoes==2){
         if((OrderType()==OP_BUY || OrderType()==OP_SELL) && OrderMagicNumber()==_MagicNumber && OrderSymbol()==Symbol()){
             ApostaMG=OrderLots()*MultiplicarGales_OB;      
         }else if(OrderProfit()==0){
             ApostaMG=OrderLots();
         }else if(OrderProfit()>0){
             ApostaMG=Aposta;
         }
       }
     }  
     
     if(AtivarMaxGales_OB==true){
         if(Aposta==1){
            if(ApostaMG>pow((Aposta*2),MaxGales_OB)){
               ApostaMG=Aposta;
            }
         }else if(ApostaMG>pow(Aposta,MaxGales_OB)){
               ApostaMG=Aposta;
         }
      }
   }
  
  void Trailling()
  {
   if(Digits==4 || Digits<=2) pip=Point;
   if(Digits==5 || Digits==3) pip=Point*10;

   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
        {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==_MagicNumber && TS>0 && OrderProfit()>0)
           {
            if(OrderType()==OP_BUY && OrderOpenPrice()+TS*pip<=Bid && OrderStopLoss()<Bid-TS*pip) w=OrderModify(OrderTicket(),OrderOpenPrice(),Bid-TS*pip,OrderTakeProfit(),0);
            if(OrderType()==OP_SELL && OrderOpenPrice()-TS*pip>=Ask && (OrderStopLoss()>Ask+TS*pip || OrderStopLoss()==0)) w=OrderModify(OrderTicket(),OrderOpenPrice(),Ask+TS*pip,OrderTakeProfit(),0);
            if(OrderType()==OP_BUY && OrderOpenPrice()+TS*pip<=Bid && OrderStopLoss()<Bid-TS*pip) w=OrderModify(OrderTicket(),OrderOpenPrice(),Bid-TS*pip,OrderTakeProfit(),0);
            if(OrderType()==OP_SELL && OrderOpenPrice()-TS*pip>=Ask && (OrderStopLoss()>Ask+TS*pip || OrderStopLoss()==0)) w=OrderModify(OrderTicket(),OrderOpenPrice(),Ask+TS*pip,OrderTakeProfit(),0);
            if(OrderType()==OP_BUY && OrderOpenPrice()+TS*pip<=Bid && OrderStopLoss()<Bid-TS*pip) w=OrderModify(OrderTicket(),OrderOpenPrice(),Bid-TS*pip,OrderTakeProfit(),0);
            if(OrderType()==OP_SELL && OrderOpenPrice()-TS*pip>=Ask && (OrderStopLoss()>Ask+TS*pip || OrderStopLoss()==0)) w=OrderModify(OrderTicket(),OrderOpenPrice(),Ask+TS*pip,OrderTakeProfit(),0);
            if(OrderType()==OP_BUY && OrderOpenPrice()+TS*pip<=Bid && OrderStopLoss()<Bid-TS*pip) w=OrderModify(OrderTicket(),OrderOpenPrice(),Bid-TS*pip,OrderTakeProfit(),0);
            if(OrderType()==OP_SELL && OrderOpenPrice()-TS*pip>=Ask && (OrderStopLoss()>Ask+TS*pip || OrderStopLoss()==0)) w=OrderModify(OrderTicket(),OrderOpenPrice(),Ask+TS*pip,OrderTakeProfit(),0);
           }
        }
     }
  }    
