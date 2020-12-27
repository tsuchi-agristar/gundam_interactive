class WorkerThread extends Thread 
{
  public static final String START  = "HTTP_START";
  public static final String RESULT = "HTTP_RESULT";
  public static final String END    = "HTTP_END";
  
  private Queue<String> queue;
  
  // Constructor
  public WorkerThread(Queue queue) {
    this.queue = queue;
  }
  
  public void run() {
    while (true) {
      if (this.queue.size() != 0) {
        String message = this.queue.poll();
        //println("message is " + message);
        
        if (message == null || message.isEmpty()) continue;
        
        switch(message)
        {
          case START:
            httpConnect.apiStart();
            break;
          
          case RESULT:
            //TO Canal
            int winner =  achievement.percentTeamA() >= achievement.percentTeamB() ? 1 : 2;
            debug_log.append("[" + debug_format.format(Calendar.getInstance().getTime()) + "] Send TCP: result start = " + winner + System.getProperty("line.separator"));
            try {
              Socket socket = new Socket(canalServer_ip, canalServer_port);
              OutputStream os = socket.getOutputStream();
              DataOutputStream dos = new DataOutputStream(os);
              if (winner == 1) {
                dos.writeBytes(end_signal_team_a);
              } else {
                dos.writeBytes(end_signal_team_b);
              }
              dos.close();   
              socket.close();
            } catch (Exception e) {
              println("Exception: TCP Result Signal");
              e.printStackTrace();
              StringWriter sw = new StringWriter();
              PrintWriter pw = new PrintWriter(sw);
              e.printStackTrace(pw);
              debug_log.append("[" + debug_format.format(Calendar.getInstance().getTime()) + "] Exception: " + sw.toString() + System.getProperty("line.separator"));
            }
            debug_log.append("[" + debug_format.format(Calendar.getInstance().getTime()) + "] Send TCP: result end = " + winner + System.getProperty("line.separator"));
          
            //TO API
            httpConnect.apiResult();
            break;
          
          case END:
            httpConnect.apiEnd();
            break;
            
          default:
            break;
        }
        
        try {
          Thread.sleep(1000);
        } catch (Exception e) {
          e.printStackTrace();
          StringWriter sw = new StringWriter();
          PrintWriter pw = new PrintWriter(sw);
          e.printStackTrace(pw);
          debug_log.append("[" + debug_format.format(Calendar.getInstance().getTime()) + "] Exception: " + sw.toString() + System.getProperty("line.separator"));
        }  
        
      } else {
        synchronized(this) {
          try {
            wait();
          } catch (Exception e) {
            e.printStackTrace();
            StringWriter sw = new StringWriter();
            PrintWriter pw = new PrintWriter(sw);
            e.printStackTrace(pw);
            debug_log.append("[" + debug_format.format(Calendar.getInstance().getTime()) + "] Exception: " + sw.toString() + System.getProperty("line.separator"));
          }
        }
      }
    }
  }
  
  public void setRequest(String message) {
    this.queue.offer(message);
    synchronized(this) {
      notifyAll();
    }
  }
}
