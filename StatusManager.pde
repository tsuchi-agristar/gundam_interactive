public class StatusManager {
  public static final int STATUS_WAITING   = 0;
  public static final int STATUS_GUIDANCE  = 1;
  public static final int STATUS_COUNT     = 2;
  public static final int STATUS_ATTACKING = 3;
  public static final int STATUS_JUDGING   = 4;
  public static final int STATUS_ENDING    = 5;
  
  private int status;
  private int start_at;
  private float elapsed_time;
  private boolean is_send_result = false;
  private boolean is_send_end = false;
  
  public int attack_countdown = -1;
  
  // Constructor
  public StatusManager() {
    status   = STATUS_WAITING;
    start_at = 0;
  }
  
  public int getStatus() {
    return status;
  }
  
  public int getCountdown() {
    return attack_countdown;
  }
  
  public int checkStatus() {
    
    switch (status) {
      case STATUS_WAITING:
      case STATUS_GUIDANCE:
        //Check START Signal received
        Client client = myServer.available();
        if (client != null) {
          String message = client.readStringUntil('\n').trim();
          println("Received start_signal: " + message);
          
          if (message.equals(start_signal) || message.equals("SCRIPTSTART") || message.equals("KEYPRESSSTART")) {
            if (status == STATUS_WAITING) {
              status = STATUS_GUIDANCE;
              start_at = millis();
              movie_guidance.jump(DEBUG_GUIDANCE_SKIP);
              workerThread.setRequest(WorkerThread.START);
            }
            debug_log.append("[" + debug_format.format(Calendar.getInstance().getTime()) + "] Received start_signal: " + message + System.getProperty("line.separator"));
          }
        }
        
        elapsed_time = (millis() - start_at) / 1000.0;
        if (movie_guidance_eos && elapsed_time >= countdown_start - DEBUG_GUIDANCE_SKIP) {
          status = STATUS_COUNT;
        }
        //println("time: " + elapsed_time + "(" + status + ")");
        break;
        
      case STATUS_COUNT:
        elapsed_time = (millis() - start_at) / 1000.0;
        if (movie_countdown_eos && elapsed_time >= battle_start - DEBUG_GUIDANCE_SKIP) {
          status = STATUS_ATTACKING;
        }
        //println("time: " + elapsed_time + "(" + status + ")");
        break;
      
      case STATUS_ATTACKING:
        elapsed_time = (millis() - start_at) / 1000.0;
        if (elapsed_time >= battle_end - DEBUG_GUIDANCE_SKIP) {
          status = STATUS_JUDGING;
        }
        //println("time: " + elapsed_time + "(" + status + ")");
        break;
      
      case STATUS_JUDGING:
        elapsed_time = (millis() - start_at) / 1000.0;
        if (!is_send_result && elapsed_time >= battle_end - DEBUG_GUIDANCE_SKIP + 1.86) {
          is_send_result = true;
          last_phase = true;
          workerThread.setRequest(WorkerThread.RESULT);
        }
      
        if (!is_send_end && elapsed_time >= battle_end - DEBUG_GUIDANCE_SKIP + 3) {
          is_send_end = true;
          workerThread.setRequest(WorkerThread.END);
        }
        
        if (elapsed_time >= battle_end - DEBUG_GUIDANCE_SKIP + 30) {
          status = STATUS_ENDING;
        }
        //println("time: " + elapsed_time + "(" + status + ")");
        break;
      
      default:
        break;
    }
    
    return status;
  }
}
