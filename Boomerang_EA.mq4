//+------------------------------------------------------------------+
//|                                                     test0909.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Desenvolvido por Jam Sávio"
#property link      "https://www.facebook.com/jamsaavio"
#property version   "2.00"

extern double Investimento = 1.0; 
extern int TempoExpiracao = 15; 
extern bool AtivarMartingale = true; 
extern double MultiplicadorMartingale=2;
extern int Expert_ID = 1234; 
double Martingale=Investimento;
int ticket=0, arrow_i=0, _MagicNumber=0;

int OnInit(){
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
    
   return(0);
}

void start(){
   TempoExpiracao=TempoExpiracao*60;
   
   // Contador
   int wins=0, losses=0;
   for(int i=0; i<=OrdersHistoryTotal(); i++){
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)){
         if(OrderProfit()>0){
            wins++;
         }
         
         if(OrderProfit()<0){
            losses++;
         }
      }
   }
   //==//
   ObjectDelete("contador");
   ObjectCreate("contador", OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,"contador",OBJPROP_XDISTANCE,760);
   ObjectSetInteger(0,"contador",OBJPROP_YDISTANCE,30);
   ObjectSetString(0,"contador",OBJPROP_TEXT,"WONs: "+wins+"   Losses: "+losses);
   ObjectSetString(0,"contador",OBJPROP_FONT,"Arial");
   ObjectSetInteger(0,"contador",OBJPROP_FONTSIZE,16);
   ObjectSetInteger(0,"contador",OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSet("contador", OBJPROP_COLOR, clrYellow);
   //==//
 
   // Martingale
   if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_HISTORY)&&AtivarMartingale==true){
         if(OrderProfit()<0 && OrderMagicNumber() == _MagicNumber){
             Martingale=OrderLots()*MultiplicadorMartingale;
         }else if(OrderProfit()==0){
             Martingale=OrderLots();
         }else if(OrderProfit()>0){
             Martingale=Investimento;
         }
   }
         
   if(Investimento==1){
      if(Martingale>=pow((Investimento*2),4)){
         Martingale=Investimento;
      }
   }
   
   else if(Martingale>=pow(Investimento,4)){
      Martingale=Investimento;
   }
   ///////////////////                   
   
    int max_contador=0;
    
   for(int e=OrdersTotal(); e>=0; e--){
      if(OrderSelect(e,SELECT_BY_POS,MODE_TRADES)){     
            if(OrderMagicNumber() == _MagicNumber && OrderSymbol() == Symbol()){
               max_contador++;
            }
        }  
     } 
   
   double down = iCustom(NULL,0,"Boomerang",0,0); 
   double up = iCustom(NULL,0,"Boomerang",1,0);
     
 if(max_contador<1){  
   if(down != 2147483647){    
      ticket=OrderSend(Symbol(),OP_SELL,NormalizeDouble(Martingale,0),Bid,0,0,0,"BO exp:"+TempoExpiracao,0,0,clrRed);
      
      if(Martingale>Investimento){
          arrow_i++;
          ObjectCreate("Down-Martingale"+arrow_i, OBJ_ARROW, 0, Time[0], High[0]+20*Point);
          ObjectSet("Down-Martingale"+arrow_i, OBJPROP_ARROWCODE, 222);
          ObjectSet("Down-Martingale"+arrow_i, OBJPROP_COLOR, clrRed);
      }
   }
   
   if(up != 2147483647){
      ticket=OrderSend(Symbol(),OP_BUY,NormalizeDouble(Martingale,0),Ask,0,0,0,"BO exp:"+TempoExpiracao,0,0,clrBlue);
      
      if(Martingale>Investimento){
          arrow_i++;
          ObjectCreate("Up-Martingale"+arrow_i, OBJ_ARROW, 0, Time[0], Low[0]-20*Point);
          ObjectSet("Up-Martingale"+arrow_i, OBJPROP_ARROWCODE, 221);
          ObjectSet("Up-Martingale"+arrow_i, OBJPROP_COLOR, clrGreen);
      }
      
   }
   }
   
}