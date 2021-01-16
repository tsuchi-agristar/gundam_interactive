public class Achievement {
  private float score_a = 0.0;
  private float score_b = 0.0;
  private float percent_a = 0.0;
  private float percent_b = 0.0;
  private float percent_a_previous = 0.0;
  private float percent_b_previous = 0.0;
  private float attack_force_a = 1.0;
  private float attack_force_b = 1.0;
  
  private HashMap team_a_user_hash = new HashMap();
  private HashMap team_b_user_hash = new HashMap();
  
  // Constructor
  public Achievement() {}
  
  public void attackTeamA(String sid) {
    team_a_user_hash.put(sid, sid);
    score_a += percent_a < 75 ? attack_force_a : attack_force_a / 4;
  }
  
  public void attackTeamB(String sid) {
    team_b_user_hash.put(sid, sid);
    score_b += percent_b < 75 ? attack_force_b : attack_force_b / 4;
  }
  
  public void setAttackForceA(float force) {
    attack_force_a = force;
  }
  
  public void setAttackForceB(float force) {
    attack_force_b = force;
  }
  
  public void substractScoreA(float score) {
    score_a -= score;
  }
  
  public void substractScoreB(float score) {
    score_b -= score;
  }
  
  public float getScoreA() {
    return score_a;
  }
  
  public float getScoreB() {
    return score_b;
  }
  
  public float percentTeamA() {
    return percent_a;
  }
  
  public float percentTeamB() {
    return percent_b;
  }
  
  public int getInferiorityTeam() {
    int team = 0;
    if (attack_force_a == attack_force_b ) team = 0;
    else if (attack_force_a > attack_force_b ) team = 1;
    else team = 2;
    return team;
  }
  
  public void calc() {
    percent_a_previous = percent_a;
    percent_b_previous = percent_b;
    
    if(score_a != 0) {
    //if(explosion_team_b == -1) {
      percent_a = score_a / (team_a_user_hash.size() * (battle_end - battle_start) * difficulty) * 100;
      if (percent_a > 100) percent_a = 100;
    //}
    }
    if(score_b != 0) {
    //if(explosion_team_a == -1) {
      percent_b = score_b / (team_b_user_hash.size() * (battle_end - battle_start) * difficulty) * 100;
      if (percent_b > 100) percent_b = 100;
    //}
    }
    
    if (explosion_team_a == -1) {
      for (int i = fixed_attacks_percent; i < 100; i += fixed_attacks_percent) {
        if (percent_a_previous < i && i <= percent_a) {
          explosion_team_a = 0;
          explosion_team_a_pos = i;
          ScheduledExecutorService achievementDecreaseScoreService = Executors.newSingleThreadScheduledExecutor();
          new FixedExecutionRunnable(new AchievementDecreaseScoreRunnable(2, score_b * fixed_attacks_down_percent / 100 / 10), 10).runNTimes(achievementDecreaseScoreService, 100, TimeUnit.MILLISECONDS);
        }
      }
    }
    
    if (explosion_team_b == -1) {
      for (int i = fixed_attacks_percent; i < 100; i += fixed_attacks_percent) {
        if (percent_b_previous < i && i <= percent_b) {
          explosion_team_b = 0;
          explosion_team_b_pos = i;
          ScheduledExecutorService achievementDecreaseScoreService = Executors.newSingleThreadScheduledExecutor();
          new FixedExecutionRunnable(new AchievementDecreaseScoreRunnable(1, score_a * fixed_attacks_down_percent / 100 / 10), 10).runNTimes(achievementDecreaseScoreService, 100, TimeUnit.MILLISECONDS);
        }
      }
    }

  }
}

class AchievementCalcRunnable implements Runnable {

  // constructor
  public AchievementCalcRunnable() {}

  public synchronized void run() {
    try {
      achievement.calc();
    } catch (Exception e) {
      println("Exception: AchievementCalcRunnable");
      e.printStackTrace();
      StringWriter sw = new StringWriter();
      PrintWriter pw = new PrintWriter(sw);
      e.printStackTrace(pw);
      debug_log.append("[" + debug_format.format(Calendar.getInstance().getTime()) + "] Exception: " + sw.toString() + System.getProperty("line.separator"));
    }
  }
}

class AchievementJudgeRunnable implements Runnable {

  // constructor
  public AchievementJudgeRunnable() {}

  public synchronized void run() {
    try {
      int percentA = (int) achievement.percentTeamA();
      int percentB = (int) achievement.percentTeamB();
      
      if (percentA != 0 || percentB != 0) {
        if (percentA >= percentB) {
          achievement.setAttackForceA(superior_attack_rate);
          achievement.setAttackForceB(1.0);
        } else {
          achievement.setAttackForceA(1.0);
          achievement.setAttackForceB(superior_attack_rate);
        }
      }
    } catch (Exception e) {
      println("Exception: AchievementJudgeRunnable");
      e.printStackTrace();
      StringWriter sw = new StringWriter();
      PrintWriter pw = new PrintWriter(sw);
      e.printStackTrace(pw);
      debug_log.append("[" + debug_format.format(Calendar.getInstance().getTime()) + "] Exception: " + sw.toString() + System.getProperty("line.separator"));
    }
  }
}

class AchievementDecreaseScoreRunnable implements Runnable {
  private int team;
  private float score;
  
  // constructor
  public AchievementDecreaseScoreRunnable(int team, float score) {
    this.team = team;
    this.score = score;
  }

  public synchronized void run() {
    try {
      if (team == 1) {
        achievement.substractScoreA(score);
      } else {
        achievement.substractScoreB(score);
      }
    } catch (Exception e) {
      println("Exception: AchievementDecreaseScoreRunnable");
      e.printStackTrace();
      StringWriter sw = new StringWriter();
      PrintWriter pw = new PrintWriter(sw);
      e.printStackTrace(pw);
      debug_log.append("[" + debug_format.format(Calendar.getInstance().getTime()) + "] Exception: " + sw.toString() + System.getProperty("line.separator"));
    }
  }
}

//https://ja.coder.work/so/java/75722
class FixedExecutionRunnable implements Runnable {
    private final AtomicInteger runCount = new AtomicInteger();
    private final Runnable delegate;
    private volatile ScheduledFuture<?> self;
    private final int maxRunCount;

    public FixedExecutionRunnable(Runnable delegate, int maxRunCount) {
        this.delegate = delegate;
        this.maxRunCount = maxRunCount;
    }

    @Override
    public void run() {
        delegate.run();
        if(runCount.incrementAndGet() == maxRunCount) {
            boolean interrupted = false;
            try {
                while(self == null) {
                    try {
                        Thread.sleep(1);
                    } catch (InterruptedException e) {
                        interrupted = true;
                    }
                }
                self.cancel(false);
            } finally {
                if(interrupted) {
                    Thread.currentThread().interrupt();
                }
            }
        }
    }

    public void runNTimes(ScheduledExecutorService executor, long period, TimeUnit unit) {
        self = executor.scheduleAtFixedRate(this, 0, period, unit);
    }
}
