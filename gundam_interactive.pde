import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;
import java.net.*;
import java.io.*;
import java.text.*;
import processing.video.*;
import processing.opengl.*;
import processing.net.*;
import http.requests.*;
import ddf.minim.*;

//Server
public Server myServer;
//public String  myServer_ip      = "10.10.150.209"; //TODO REAL Address "10.10.150.209"
public String  myServer_ip      = "127.0.0.1"; //TODO REAL Address "10.10.150.209"
public Integer myServer_port    = 10002;
//public String  canalServer_ip   = "10.10.150.101"; //TODO REAL Address "10.10.150.101"
public String  canalServer_ip   = "127.0.0.1"; //TODO REAL Address "10.10.150.101"
public Integer canalServer_port = 1702;
//public String  apiServer_url    = "https://gundamapi.azurewebsites.net"; //TODO REAL URL https://gundamapi.azurewebsites.net
public String  apiServer_url    = "https://gundamapim.azurewebsites.net"; //TODO REAL URL https://gundamapi.azurewebsites.net

//Signal
//TeamA: NeoZiong, TeamB: GUNDAM
public String start_signal      = "START1";
public String end_signal_team_a = "ct TRG2\r\n"; //NeoZiong
public String end_signal_team_b = "ct TRG1\r\n"; //GUNDAM

//Game Time
public float countdown_start = 109.18; //TODO 01:49.18
public float battle_start    = 121.00; //TODO 02:01.00
public float battle_end      = 159.14; //TODO 02:39.14
public float DEBUG_GUIDANCE_SKIP = 0;  //FOR DEBUG 80.0

//Energy
public PImage energy_img;
public int energy_images = 5;          //TODO energy ball speed
public float energy_size_ratio = 0.05; //TODO energy ball size
public int energy_per_frame = 10;      //TODO energy number from quese per frame

//Explosion
public int explosion_images = 68;
public PImage explosion_team_a_img[];
public PImage explosion_team_b_img[];
public int explosion_team_a = -1;
public int explosion_team_b = -1;
public int explosion_team_a_pos = 0;
public int explosion_team_b_pos = 0;

//Display Area (115[x], 0[y], 1690[w], 951[h])
public int x_margin = 115;
public int display_width = 1690;
public int display_height = 951;

//Log
public SimpleDateFormat debug_format = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
public StringBuffer debug_log = new StringBuffer();

//Game Status Manager
public StatusManager statusManager;

//Worker Thread
public WorkerThread workerThread;

//HTTP Connection for API
public HttpConnect httpConnect;

//Energy Manager
public EnergyManager energyManager;

//Achievement
public Achievement achievement;
public ScheduledExecutorService achievementJudgeService;
public ScheduledFuture<?> achievementJudgeScheduledFuture;

//energy_ball Queue
public BlockingQueue<Integer> energyDataQueue;

//Game Setting
public float difficulty = 1.0;
public float superior_attack_rate = 0.8;
public int judge_seconds = 5;
public int fixed_attacks_percent = 25;
public int fixed_attacks_down_percent = 10;
public int game_id = 0;

//Background
public PImage background;
//Star
public PImage star;

//Indicator Position of A Team
public float ind_a_pos_upper_left_x = x_margin + 372;
public float ind_a_pos_upper_left_y = 300;
public float ind_a_pos_lower_right_x = x_margin + 417;
public float ind_a_pos_lower_right_y = 475;
//Energy Start and End Position of A Team
public float energy_ball_start_a_x = ind_a_pos_upper_left_x + (ind_a_pos_lower_right_x - ind_a_pos_upper_left_x) / 2;
public float energy_ball_start_a_y = display_height - 50;
public float energy_ball_end_a_x = ind_a_pos_upper_left_x + (ind_a_pos_lower_right_x - ind_a_pos_upper_left_x) / 2;
public float energy_ball_end_a_y = ind_a_pos_lower_right_y - 15;

//Indicator Position of B Team
public float ind_b_pos_upper_left_x = x_margin + 1215;
public float ind_b_pos_upper_left_y = 300;
public float ind_b_pos_lower_right_x = x_margin + 1260;
public float ind_b_pos_lower_right_y = 475;
//Energy Start and End Position of B Team
public float energy_ball_start_b_x = ind_b_pos_upper_left_x + (ind_b_pos_lower_right_x - ind_b_pos_upper_left_x) / 2;
public float energy_ball_start_b_y = display_height - 50;
public float energy_ball_end_b_x = ind_b_pos_upper_left_x + (ind_b_pos_lower_right_x - ind_b_pos_upper_left_x) / 2;
public float energy_ball_end_b_y = ind_b_pos_lower_right_y - 15;

//Movie
public Movie movie_guidance;
public boolean movie_guidance_eos = false;
public Movie movie_countdown;
public boolean movie_countdown_eos = false;
//Audio
public Minim minim; //lib
public AudioPlayer bgm;
//Font
public PFont font;
//Flag
public boolean last_phase = false;

void settings() {
  noSmooth();
  fullScreen(2); //Display on 2nd Monitor
}

void setup() {
    debug_log.append("[" + debug_format.format(Calendar.getInstance().getTime()) + "] setup() start" + System.getProperty("line.separator"));
    frameRate(30);
    
    //Start Server in order to receive START Signal
    myServer = new Server(this, myServer_port, myServer_ip);
    debug_log.append("[" + debug_format.format(Calendar.getInstance().getTime()) + "] start server at address: " + Server.ip() + System.getProperty("line.separator"));
    
    statusManager = new StatusManager();
    
    workerThread = new WorkerThread(new ArrayDeque<String>());
    workerThread.start();
    
    httpConnect = new HttpConnect();
    energyDataQueue = new LinkedBlockingQueue<Integer>();
    ScheduledExecutorService apiService = Executors.newSingleThreadScheduledExecutor();
    apiService.scheduleAtFixedRate(new ApiDataRunnable(energyDataQueue), 5000, 500, TimeUnit.MILLISECONDS);
    
    energyManager = new EnergyManager();
    
    achievement = new Achievement();
    ScheduledExecutorService achievementCalcService = Executors.newSingleThreadScheduledExecutor();
    achievementCalcService.scheduleAtFixedRate(new AchievementCalcRunnable(), 5000, 100, TimeUnit.MILLISECONDS);
    achievementJudgeService = Executors.newSingleThreadScheduledExecutor();
    achievementJudgeScheduledFuture = achievementJudgeService.scheduleAtFixedRate(new AchievementJudgeRunnable(), judge_seconds, judge_seconds, TimeUnit.SECONDS);
    
    background = loadImage("gundam_bg.png");
    star = loadImage("star.png");
    
    //Prepair Explosion images
    explosion_team_a_img = new PImage[explosion_images];
    for (int i = 0; i < explosion_images; i++) {
      explosion_team_a_img[i] = loadImage("explosion\\" + i + ".png").get(360, 270, 1200, 600);
    }
    FlipFilter ff = new FlipFilter();
    ff.setOperation(FlipFilter.FLIP_H);
    explosion_team_b_img = new PImage[explosion_images];
    for (int i = 0; i < explosion_images; i++) {
      explosion_team_b_img[i] = new PImage(ff.filter((java.awt.image.BufferedImage) explosion_team_a_img[i].getImage(), null));
    }
    
    energy_img = loadImage("energy_ball.png");
    
    movie_guidance  = new Movie(this, "guidance.mp4"){ @Override public void eosEvent() { super.eosEvent(); movie_guidance_eos = true;}};
    movie_countdown = new Movie(this, "countdown.mp4"){ @Override public void eosEvent() { super.eosEvent(); movie_countdown_eos = true;}};
    minim = new Minim(this);
    bgm   = minim.loadFile("bgm.wav");
    font  = loadFont("OPTIBankGothic-Medium-72.vlw");
    
    //Initialize Movie And Audio
    movie_guidance.play();
    movie_guidance.pause();
    movie_countdown.play();
    movie_countdown.pause();
    bgm.play();
    bgm.pause();
    
    //Cache Thread
    ScheduledExecutorService cacheService = Executors.newSingleThreadScheduledExecutor();
    cacheService.scheduleAtFixedRate(new CacheRunnable(), 1000, 500, TimeUnit.MILLISECONDS);

    debug_log.append("[" + debug_format.format(Calendar.getInstance().getTime()) + "] setup() end" + System.getProperty("line.separator"));
}

void draw() {
    //FrameRate Check
    if(frameRate < 29 && statusManager.checkStatus() != StatusManager.STATUS_WAITING) {
      println("frameRate= " + frameRate);
    }
    
    background(0, 0, 0);
    noCursor();

    switch (statusManager.checkStatus()) {
      case StatusManager.STATUS_WAITING:
        fill(255);
        textSize(20);
        textAlign(LEFT);
        text("Ready...", 10, 35);
        break;
        
      case StatusManager.STATUS_GUIDANCE:
        if(!movie_guidance_eos) {
          movie_guidance.play();
          image(movie_guidance, x_margin, 0, display_width, display_height);
        } else {
          movie_guidance.stop();
        }
        
        break;
        
      case StatusManager.STATUS_COUNT:
        if (!movie_countdown_eos) {
          movie_countdown.play();
          image(movie_countdown, x_margin, 0, display_width, display_height);
        } else {
          movie_countdown.stop();
        }
        
        //background
        image(background, x_margin, 0, display_width, display_height);
        
        //Display Percent
        noStroke();
        fill(255, 255, 255);
        textFont(font, 28);
        textAlign(RIGHT, BOTTOM);
        text(0, ind_a_pos_lower_right_x -15, ind_a_pos_upper_left_y -10);
        text(0, ind_b_pos_lower_right_x -25, ind_b_pos_upper_left_y -10);
        
        //Display Star
        imageMode(CENTER);
        for (int i = fixed_attacks_percent; i < 100; i += fixed_attacks_percent) {
           image(star, ind_a_pos_upper_left_x + (ind_a_pos_lower_right_x - ind_a_pos_upper_left_x) / 2 + 3, ind_a_pos_lower_right_y - ((ind_a_pos_lower_right_y - ind_a_pos_upper_left_y) * i / 100), star.width * 0.9, star.height * 0.9);
           image(star, ind_b_pos_upper_left_x + (ind_b_pos_lower_right_x - ind_b_pos_upper_left_x) / 2 - 1, ind_b_pos_lower_right_y - ((ind_b_pos_lower_right_y - ind_b_pos_upper_left_y) * i / 100), star.width * 0.9, star.height * 0.9);
        }
        imageMode(CORNER);
        break;
        
      case StatusManager.STATUS_ATTACKING:
        //bgm.play();
        
        //Display Percent and Indicator
        {
          int percentA = (int) achievement.percentTeamA();
          int percentB = (int) achievement.percentTeamB();
          float a_percent_lenght = (ind_a_pos_lower_right_y - ind_a_pos_upper_left_y) / 100 * percentA;
          float b_percent_lenght = (ind_b_pos_lower_right_y - ind_b_pos_upper_left_y) / 100 * percentB;
          noStroke();
          fill(255, 255, 255);
          textFont(font, 28);
          textAlign(RIGHT, BOTTOM);
          text(percentA, ind_a_pos_lower_right_x -15, ind_a_pos_upper_left_y -10);
          text(percentB, ind_b_pos_lower_right_x -25, ind_b_pos_upper_left_y -10);
          //fill(135, 255, 255); // Indicator Color
          rect(ind_a_pos_upper_left_x, ind_a_pos_lower_right_y - a_percent_lenght, ind_a_pos_lower_right_x - ind_a_pos_upper_left_x, a_percent_lenght);
          rect(ind_b_pos_upper_left_x, ind_b_pos_lower_right_y - b_percent_lenght, ind_b_pos_lower_right_x - ind_b_pos_upper_left_x, b_percent_lenght);
          
          int inferiorityTeam = achievement.getInferiorityTeam();
          fill(255, 0, 0);
          if ((last_phase || inferiorityTeam == 1) && frameCount % 10 < 5) {
            rect(ind_a_pos_upper_left_x, ind_a_pos_lower_right_y - a_percent_lenght, ind_a_pos_lower_right_x - ind_a_pos_upper_left_x, a_percent_lenght);
          } 
          if ((last_phase || inferiorityTeam == 2) && frameCount % 10 < 5) {
            rect(ind_b_pos_upper_left_x, ind_b_pos_lower_right_y - b_percent_lenght, ind_b_pos_lower_right_x - ind_b_pos_upper_left_x, b_percent_lenght);
          }
          
          fill(0, 0, 0);
          rect(ind_a_pos_upper_left_x, ind_a_pos_upper_left_y +30, 4, 27);
          rect(ind_a_pos_upper_left_x, ind_a_pos_upper_left_y +74, 4, 27);
          rect(ind_a_pos_upper_left_x, ind_a_pos_upper_left_y +118, 4, 27);
          rect(ind_b_pos_lower_right_x -4, ind_b_pos_upper_left_y +30, 4, 27);
          rect(ind_b_pos_lower_right_x -4, ind_b_pos_upper_left_y +74, 4, 27);
          rect(ind_b_pos_lower_right_x -4, ind_b_pos_upper_left_y +118, 4, 27);
        }
        
        image(background, x_margin, 0, display_width, display_height);
        
        imageMode(CENTER);
        //Display Star
        for (int i = fixed_attacks_percent; i < 100; i += fixed_attacks_percent) {
          if (explosion_team_a == -1 || explosion_team_a_pos != i) {
            image(star, ind_a_pos_upper_left_x + (ind_a_pos_lower_right_x - ind_a_pos_upper_left_x) / 2 + 3, ind_a_pos_lower_right_y - ((ind_a_pos_lower_right_y - ind_a_pos_upper_left_y) * i / 100), star.width * 0.9, star.height * 0.9);
          }
          if (explosion_team_b == -1 || explosion_team_b_pos != i) {
            image(star, ind_b_pos_upper_left_x + (ind_b_pos_lower_right_x - ind_b_pos_upper_left_x) / 2 - 1, ind_b_pos_lower_right_y - ((ind_b_pos_lower_right_y - ind_b_pos_upper_left_y) * i / 100), star.width * 0.9, star.height * 0.9);
          }
        }
        
        //Display Explosion
        if (explosion_team_a != -1) {
          image(explosion_team_a_img[explosion_team_a], 970, ind_a_pos_lower_right_y - ((ind_a_pos_lower_right_y - ind_a_pos_upper_left_y) * explosion_team_a_pos / 100), explosion_team_a_img[explosion_team_a].width * 0.9, explosion_team_a_img[explosion_team_a].height * 0.9);
          explosion_team_a++;
          if (explosion_team_a == explosion_images) explosion_team_a = -1;
        }
        if (explosion_team_b != -1) {
          image(explosion_team_b_img[explosion_team_b], 900, ind_b_pos_lower_right_y - ((ind_b_pos_lower_right_y - ind_b_pos_upper_left_y) * explosion_team_b_pos / 100), explosion_team_b_img[explosion_team_b].width * 0.9, explosion_team_b_img[explosion_team_b].height * 0.9);
          explosion_team_b++;
          if (explosion_team_b == explosion_images) explosion_team_b = -1;
        }
        imageMode(CORNER);
        
        //poll Energy from Queue
        try {
          int currentQueueSize = energyDataQueue.size();
          for (int i = 0; i < energy_per_frame && currentQueueSize -i > 0; i++) {
            energyManager.setEnergy(energyDataQueue.take());
          }
        } catch (Exception e) {
          println("Exception: Queue take()");
          e.printStackTrace();
          StringWriter sw = new StringWriter();
          PrintWriter pw = new PrintWriter(sw);
          e.printStackTrace(pw);
          debug_log.append("[" + debug_format.format(Calendar.getInstance().getTime()) + "] Exception: " + sw.toString() + System.getProperty("line.separator"));
        }
        
        //draw energy
        energyManager.energyDraw();
        break;
        
      case StatusManager.STATUS_JUDGING:
        bgm.pause();
        //String message = "BATTLE OVER!!";
        //textFont(font, 72);
        //textAlign(CENTER);
        //fill(255, 165, 0);
        //for (int x = -1; x < 2; x++) {
        //  text(message, width/2 , x + height/2);
        //}
        //fill(255, 215, 0);
        //text(message, width/2 , height/2);
        break;
        
      case StatusManager.STATUS_ENDING:
        //Quit Application
        bgm.close();
        minim.stop();
        SimpleDateFormat sdf_log = new SimpleDateFormat("yyyyMMdd_HHmmss");
        PrintWriter output = createWriter("log\\log_" + sdf_log.format(Calendar.getInstance().getTime()) + ".txt");
        output.println(debug_log.toString());
        output.flush();
        output.close();
        myServer.stop();
        myServer = null;
        exit();
        break;
        
      default:
        break;
    }
}

//Movie
void movieEvent(Movie m) {
  m.read();
}

//Cache Thread
class CacheRunnable implements Runnable {

    public CacheRunnable() {}

    public synchronized void run() {
      switch (statusManager.getStatus()) {
        case StatusManager.STATUS_WAITING:
          movie_guidance.pause();
          movie_countdown.pause();
          bgm.pause();
          break;
          
        case StatusManager.STATUS_GUIDANCE:
        case StatusManager.STATUS_COUNT:
        case StatusManager.STATUS_ATTACKING:
          for (int i = 0; i < explosion_images; i++) {
             image(explosion_team_a_img[i], 0, 0, 0, 0);
             image(explosion_team_b_img[i], 0, 0, 0, 0);
          }
          image(background, 0, 0, 0, 0);
          image(star, 0, 0, 0, 0);
          image(energy_img, 0, 0, 0, 0);
          break;
          
        default:
          break;
      }
    }
}

//Debug
void keyPressed() {
    switch (key) {
      case 'S':
        //Send Start Signal
        try {
          Socket socket = new Socket(myServer_ip, myServer_port);
          OutputStream os = socket.getOutputStream();
          DataOutputStream dos = new DataOutputStream(os);
          dos.writeBytes("KEYPRESSSTART\n");
          dos.close();
          socket.close();
        } catch (Exception e) {}
        break;
        
      case 'Q':
        //Quit Application
        SimpleDateFormat sdf_log = new SimpleDateFormat("yyyyMMdd_HHmmss");
        PrintWriter output = createWriter("log\\log_" + sdf_log.format(Calendar.getInstance().getTime()) + ".txt");
        output.println(debug_log.toString());
        output.flush();
        output.close();
        myServer.stop();
        myServer = null;
        exit();
        break;
        
      case 'z':
        try {
          energyDataQueue.put(1);
          achievement.attackTeamA("zzz0");
          energyDataQueue.put(1);
          achievement.attackTeamA("zzz1");
          energyDataQueue.put(1);
          achievement.attackTeamA("zzz2");
          energyDataQueue.put(1);
          achievement.attackTeamA("zzz3");
          energyDataQueue.put(1);
          achievement.attackTeamA("zzz4");
          energyDataQueue.put(1);
          achievement.attackTeamA("zzz5");
          energyDataQueue.put(1);
          achievement.attackTeamA("zzz6");
          energyDataQueue.put(1);
          achievement.attackTeamA("zzz7");
          energyDataQueue.put(1);
          achievement.attackTeamA("zzz8");
          energyDataQueue.put(1);
          achievement.attackTeamA("zzz9");
        } catch (Exception e) {}
        break;
        
      case 'x':
        try {
          energyDataQueue.put(2);
          achievement.attackTeamB("xxx0");
          energyDataQueue.put(2);
          achievement.attackTeamB("xxx1");
          energyDataQueue.put(2);
          achievement.attackTeamB("xxx2");
          energyDataQueue.put(2);
          achievement.attackTeamB("xxx3");
          energyDataQueue.put(2);
          achievement.attackTeamB("xxx4");
          energyDataQueue.put(2);
          achievement.attackTeamB("xxx5");
          energyDataQueue.put(2);
          achievement.attackTeamB("xxx6");
          energyDataQueue.put(2);
          achievement.attackTeamB("xxx7");
          energyDataQueue.put(2);
          achievement.attackTeamB("xxx8");
          energyDataQueue.put(2);
          achievement.attackTeamB("xxx9");
        } catch (Exception e) {}
        break;
    }
}
