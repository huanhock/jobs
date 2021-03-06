#property copyright "Copyright 2017, Desenvolvido por Jam Sávio."
#property link      "https://www.facebook.com/groups/428419167512603/"
#property version   "2.00"

extern int qnt_velas=20;
extern int qnt_pontos_max=1500;
extern int qnt_pontos_min=500;
extern string separador="//----------------------------------";
extern int porcentagem_zona_neutra=10;
extern int porcentagem_margem_erro=10;
extern string separador2="//----------------------------------";
extern int num_rebatidas=1; 
extern string separador3="//----------------------------------";
extern bool tp_em_canais=true;
extern int tp_qnt_canais=1;
extern int tp_em_pontos=300;
extern string separador4="//----------------------------------";
extern bool stop_loss_fundo=true;
extern int sl_em_pontos=150;
extern string separador5="//----------------------------------";
extern double multiplicador_lotes=1.5;
extern double lote_inicial=0.01;
extern string separador6="//----------------------------------";
extern bool trailling_stop=true;
extern int TS=35;
extern string separador7="//----------------------------------";
extern int Expert_ID = 1234; 
//-------------------------------------------------------------------+
int qnt_rebates=0, ticket, _MagicNumber=0;;
double pip,Martingale=lote_inicial;
datetime CurrentTimeStamp;     
double Maior, Menor, margem_resistencia, margem_suporte, zona_resistencia, zona_suporte, take_venda, take_compra;
bool qnt_min=false;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
void OnInit()
{
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
    
   AtualizaCanal();
}
  
  
int start()
{
   if(OrdersContador()==0){
      Martingale_FX();
      
      //+----------------------------------------------+
         
         take_venda = zona_suporte-(margem_resistencia-zona_suporte)*tp_qnt_canais;
         take_compra = zona_resistencia+(zona_resistencia-margem_suporte)*tp_qnt_canais;
         // takes virtuais
         
         if(Ask >= take_compra || Bid <= take_venda) AtualizaCanal();
         //Se o preço atingir o "take virtual", atualiza o canal.
           
         if(margem_resistencia-margem_suporte > qnt_pontos_max * Point) AtualizaCanal(); 
         //Se o canal for maior que quantidade de pontos pré-estabelecida, atualiza o canal.
         
         if(margem_resistencia-margem_suporte < qnt_pontos_min * Point){
            AtualizaCanal();
            qnt_min=true;
         }else{
            qnt_min=false;
         }
         //Se o canal for menor que quantidade de pontos pré-estabelecida, atualiza o canal.
         
         if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_HISTORY) && ticket != 6969){
            if(OrderProfit()<=0){
               if(OrderType()==OP_BUY) Venda();
               if(OrderType()==OP_SELL) Compra();
            }
            if(OrderProfit()>0){ 
               AtualizaCanal();
               ticket=6969;
            }
         }
         //Se a última ordem foi com lucro, então atualiza o canal, senão, então abre uma ordem contrária.
         
      //+----------------------------------------------+
      
      if((Ask>=margem_resistencia || Bid<=margem_suporte) && CurrentTimeStamp != Time[0]){
            bool compra=false, venda=false;
            
            if(Ask>=margem_resistencia){ 
               compra=true;
               venda=false;
               qnt_rebates++;
            }
            
            if(Bid<=margem_suporte){
               compra=false;
               venda=true;
               qnt_rebates++;
            }
            
            if(qnt_rebates>=num_rebatidas&&OrdersTotal()==0&&qnt_min==false){
               qnt_rebates=0;
               if(venda==true) Venda();
               if(compra==true) Compra();
            }
            
            CurrentTimeStamp = Time[0];
      }
   }else{ //Main
         if(trailling_stop==true){ Trailling(); } 
   }
   
   //Comment("Tocou: "+qnt_rebates+"x // Take virtual de compra: "+NormalizeDouble(take_compra,5)+" // Take virtual de venda: "+NormalizeDouble(take_venda,5)+" // Pontos max: "+NormalizeDouble(qnt_pontos_max*Point,5)+" // Pontos min: "+NormalizeDouble(qnt_pontos_min*Point,5)+" // Pontos canal: "+(margem_resistencia-margem_suporte)+" // Qnt_min: "+qnt_min+" // Ticket: "+ticket);
   //Debugging
   return(0);
}

//+-----------------------------------------------------------------------------------------+
//+-----------------------------------FUNÇÕES-----------------------------------------------+
//+-----------------------------------------------------------------------------------------+

void AtualizaCanal(){
   Maior=High[0];
   Menor=Low[0];
      
   for(int i=0; i<=qnt_velas; i++){
      if(High[i]>Maior){
           Maior=High[i];
      }
      
      if(Low[i]<Menor){
           Menor=Low[i];
      }
   }

    margem_resistencia = Maior+(Maior-Menor)*porcentagem_margem_erro/100;
    margem_suporte = Menor-(Maior-Menor)*porcentagem_margem_erro/100;
    zona_resistencia = margem_resistencia+(margem_resistencia-margem_suporte)*porcentagem_zona_neutra/100;
    zona_suporte = margem_suporte-(margem_resistencia-margem_suporte)*porcentagem_zona_neutra/100;
   
    ObjectDelete("resistencia");
    ObjectDelete("resistencia_max");
    ObjectDelete("margem_resistencia");
    ObjectDelete("suporte");
    ObjectDelete("margem_suporte");
    ObjectDelete("suporte_min");
    
    ObjectCreate("resistencia", OBJ_HLINE, 0, Time[0], Maior, 0, 0);
    ObjectSet("resistencia", OBJPROP_COLOR, Yellow);
    ObjectSet("resistencia", OBJPROP_WIDTH, 3);
   
    ObjectCreate("margem_resistencia", OBJ_HLINE, 0, Time[0], margem_resistencia, 0, 0);
    ObjectSet("margem_resistencia", OBJPROP_COLOR, Green);
    ObjectSet("margem_resistencia", OBJPROP_WIDTH, 3);
   
    ObjectCreate("resistencia_max", OBJ_HLINE, 0, Time[0], zona_resistencia, 0, 0);
    ObjectSet("resistencia_max", OBJPROP_COLOR, Blue);
    ObjectSet("resistencia_max", OBJPROP_STYLE, STYLE_DASH);
   
    ObjectCreate("suporte", OBJ_HLINE, 0, Time[0], Menor, 0, 0);
    ObjectSet("suporte", OBJPROP_COLOR, Yellow);
    ObjectSet("suporte", OBJPROP_WIDTH, 3);
   
    ObjectCreate("margem_suporte", OBJ_HLINE, 0, Time[0], margem_suporte, 0, 0);
    ObjectSet("margem_suporte", OBJPROP_COLOR, Green);
    ObjectSet("margem_suporte", OBJPROP_WIDTH, 3);
   
    ObjectCreate("suporte_min", OBJ_HLINE, 0, Time[0], zona_suporte, 0, 0);
    ObjectSet("suporte_min", OBJPROP_COLOR, Blue);
    ObjectSet("suporte_min", OBJPROP_STYLE, STYLE_DASH);
}
//-------------------------------------------------------------------------------------------

void Compra(){
            if(tp_em_canais==false && stop_loss_fundo==false){
               ticket = OrderSend(Symbol(),OP_BUY,Martingale,Ask,0,Ask-sl_em_pontos*Point,Ask+tp_em_pontos*Point,"",_MagicNumber,0,clrBlue);
            }
            
            else if(tp_em_canais==true && stop_loss_fundo==false){
                ticket = OrderSend(Symbol(),OP_BUY,Martingale,Ask,0,Ask-sl_em_pontos*Point,take_compra,"",_MagicNumber,0,clrBlue);   
            }
            
            else if(tp_em_canais==false && stop_loss_fundo==true){
                ticket = OrderSend(Symbol(),OP_BUY,Martingale,Ask,0,margem_suporte,Ask+tp_em_pontos*Point,"",_MagicNumber,0,clrBlue);
            }
            
            else if(tp_em_canais==true && stop_loss_fundo==true){
                ticket = OrderSend(Symbol(),OP_BUY,Martingale,Ask,0,margem_suporte,take_compra,"",_MagicNumber,0,clrBlue);
            }
}
 
void Venda(){
            if(tp_em_canais==false && stop_loss_fundo==false){
               ticket = OrderSend(Symbol(),OP_SELL,Martingale,Bid,0,Bid+sl_em_pontos*Point,Bid-tp_em_pontos*Point,"",_MagicNumber,0,clrRed);
            }
            
            else if(tp_em_canais==true && stop_loss_fundo==false){
               ticket = OrderSend(Symbol(),OP_SELL,Martingale,Bid,0,Bid+sl_em_pontos*Point,take_venda,"",_MagicNumber,0,clrRed);
            }
            
            else if(tp_em_canais==false && stop_loss_fundo==true){
               ticket = OrderSend(Symbol(),OP_SELL,Martingale,Bid,0,margem_resistencia,Bid-tp_em_pontos*Point,"",_MagicNumber,0,clrRed);
            }
            
            else if(tp_em_canais==true && stop_loss_fundo==true){
               ticket = OrderSend(Symbol(),OP_SELL,Martingale,Bid,0,margem_resistencia,take_venda,"",_MagicNumber,0,clrRed);
            }
}
//-------------------------------------------------------------------------------------------

void Martingale_FX(){
   for(int i=0; i<=OrdersHistoryTotal(); i++){   
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==true){
         if((OrderType()==OP_BUY || OrderType()==OP_SELL) && OrderMagicNumber()==_MagicNumber && OrderSymbol()==Symbol()){
            if(OrderProfit()<0){
                  if(Martingale==0.01) Martingale=0.02;
                  else Martingale=OrderLots()*multiplicador_lotes;  
            }else if(OrderProfit()==0){
                  Martingale=OrderLots();
            }else if(OrderProfit()>0){
                  Martingale=lote_inicial;
            }
          }
       }
       else{ 
         Print("Access to history failed with error (",GetLastError(),")");
       }
    }
}
//-------------------------------------------------------------------------------------------

void Trailling(){
   bool w;  
//--- 1.1. Define pip -----------------------------------------------------
   if(Digits==4 || Digits<=2) pip=Point;
   if(Digits==5 || Digits==3) pip=Point*10;

//--- 1.2. Trailing -------------------------------------------------------
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
        {
         if(OrderSymbol()==Symbol() && TS>0 && OrderProfit()>0)
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
//-------------------------------------------------------------------------------------------

int OrdersContador(){
   int c=0;
   for(int i=0; i<=OrdersTotal(); i++){
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)==true){
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==_MagicNumber){
            c++;  
         }
      }
   }
   return(c);
}