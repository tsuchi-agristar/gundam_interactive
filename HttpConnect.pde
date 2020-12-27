class HttpConnect {
  // constructor
  HttpConnect() {}
  
  public void apiStart() {
    debug_log.append("[" + debug_format.format(Calendar.getInstance().getTime()) + "] apiStart() start" + System.getProperty("line.separator"));
    for (;;) {
      try {
        PostRequest post = new PostRequest(apiServer_url + "/api/processing/start");
        post.addHeader("Content-Type", "application/json");
        JSONObject postJson = new JSONObject();
        postJson.setLong("start_time", System.currentTimeMillis()/1000);
        post.addJson(postJson.toString());
        post.send();
        String response = post.getContent();
        debug_log.append("[" + debug_format.format(Calendar.getInstance().getTime()) + "] Reqest: " + postJson.toString() +  ", Reponse: " + response + System.getProperty("line.separator"));
        
        //Game Settings
        if (response.startsWith("{")) {
          JSONObject ResponseJson = parseJSONObject(response);
          if (!ResponseJson.isNull("game_id")) {
            game_id = ResponseJson.getInt("game_id");
            difficulty = ResponseJson.getFloat("difficulty");
            superior_attack_rate = ResponseJson.getFloat("superior_attack_rate");
            judge_seconds = ResponseJson.getInt("judge_seconds");
            fixed_attacks_percent = ResponseJson.getInt("fixed_attacks_percent");
            fixed_attacks_down_percent = ResponseJson.getInt("fixed_attacks_down_percent");
            
            achievementJudgeScheduledFuture.cancel(true);
            achievementJudgeScheduledFuture = achievementJudgeService.scheduleAtFixedRate(new AchievementJudgeRunnable(), judge_seconds, judge_seconds, TimeUnit.SECONDS);
            break;
          }
        } else {
          try {
            Thread.sleep(500);
          } catch (Exception e) {
            e.printStackTrace();
          }
        }
      } catch (Exception e) {
        println("Exception: HttpConnect apiStart()");
        e.printStackTrace();
        StringWriter sw = new StringWriter();
        PrintWriter pw = new PrintWriter(sw);
        e.printStackTrace(pw);
        debug_log.append("[" + debug_format.format(Calendar.getInstance().getTime()) + "] Exception: " + sw.toString() + System.getProperty("line.separator"));
        try {
          Thread.sleep(500);
        } catch (Exception x) {
          x.printStackTrace();
        }
      }
    }
    debug_log.append("[" + debug_format.format(Calendar.getInstance().getTime()) + "] apiStart() end" + System.getProperty("line.separator"));
  }

  public void apiResult() {
    debug_log.append("[" + debug_format.format(Calendar.getInstance().getTime()) + "] apiResult() start" + System.getProperty("line.separator"));
    for (;;) {
      try {
        PostRequest post = new PostRequest(apiServer_url + "/api/processing/result");
        post.addHeader("Content-Type", "application/json");
        JSONObject postJson = new JSONObject();
        postJson.setInt("game_id", game_id);
        postJson.setFloat("difficulty", difficulty);
        postJson.setInt("winner", achievement.percentTeamA() >= achievement.percentTeamB() ? 1 : 2);
        postJson.setFloat("a_score", achievement.getScoreA());
        postJson.setFloat("b_score", achievement.getScoreB());
        post.addJson(postJson.toString());
        post.send();
        String response = post.getContent();
        debug_log.append("[" + debug_format.format(Calendar.getInstance().getTime()) + "] Reqest: " + postJson.toString() +  ", Reponse: " + response + System.getProperty("line.separator"));
        
        if (response.startsWith("{")) {
          JSONObject ResponseJson = parseJSONObject(response);
          if (!ResponseJson.isNull("game_id")) {
            break;
          }
        } else {
          try {
            Thread.sleep(500);
          } catch (Exception e) {
            e.printStackTrace();
          }
        }
      } catch (Exception e) {
        println("Exception: HttpConnect apiResult()");
        e.printStackTrace();
        StringWriter sw = new StringWriter();
        PrintWriter pw = new PrintWriter(sw);
        e.printStackTrace(pw);
        debug_log.append("[" + debug_format.format(Calendar.getInstance().getTime()) + "] Exception: " + sw.toString() + System.getProperty("line.separator"));
        try {
          Thread.sleep(500);
        } catch (Exception x) {
          x.printStackTrace();
        }
      }
    }
    debug_log.append("[" + debug_format.format(Calendar.getInstance().getTime()) + "] apiResult() end" + System.getProperty("line.separator"));
  }
  
  public void apiEnd() {
    debug_log.append("[" + debug_format.format(Calendar.getInstance().getTime()) + "] apiEnd() start" + System.getProperty("line.separator"));
    for (;;) {
      try {
        PostRequest post = new PostRequest(apiServer_url + "/api/processing/end");
        post.addHeader("Content-Type", "application/json");
        JSONObject postJson = new JSONObject();
        postJson.setInt("game_id", game_id);
        postJson.setFloat("difficulty", difficulty);
        postJson.setLong("end_time", System.currentTimeMillis()/1000);
        post.addJson(postJson.toString());
        post.send();
        String response = post.getContent();
        debug_log.append("[" + debug_format.format(Calendar.getInstance().getTime()) + "] Reqest: " + postJson.toString() +  ", Reponse: " + response + System.getProperty("line.separator"));
        
        if (response.startsWith("{")) {
          JSONObject ResponseJson = parseJSONObject(response);
          if (!ResponseJson.isNull("game_id")) {
            break;
          }
        } else {
          try {
            Thread.sleep(500);
          } catch (Exception e) {
            e.printStackTrace();
          }
        }
      } catch (Exception e) {
        println("Exception: HttpConnect apiEnd()");
        e.printStackTrace();
        StringWriter sw = new StringWriter();
        PrintWriter pw = new PrintWriter(sw);
        e.printStackTrace(pw);
        debug_log.append("[" + debug_format.format(Calendar.getInstance().getTime()) + "] Exception: " + sw.toString() + System.getProperty("line.separator"));
        try {
          Thread.sleep(500);
        } catch (Exception x) {
          x.printStackTrace();
        }
      }
    }
    debug_log.append("[" + debug_format.format(Calendar.getInstance().getTime()) + "] apiEnd() end" + System.getProperty("line.separator"));
  }
}

class ApiDataRunnable implements Runnable {

  private int id = 0;
  private BlockingQueue<Integer> queue;

  // constructor
  public ApiDataRunnable(BlockingQueue<Integer> queue) {
    this.queue = queue;
  }

  public synchronized void run() {
    if (game_id != 0) {
      try {
        PostRequest post = new PostRequest(apiServer_url + "/api/processing/data");
        post.addHeader("Content-Type", "application/json");
        JSONObject postJson = new JSONObject();
        postJson.setInt("id", id);
        post.addJson(postJson.toString());
        post.send();
        String response = post.getContent();
        //debug_log.append("[" + debug_format.format(Calendar.getInstance().getTime()) + "] Reqest: " + postJson.toString() +  ", Reponse: " + response + System.getProperty("line.separator"));
        
        response = response.replace("[", "{ \"datas\": [").replace("]", "]}");
        if (response.startsWith("{")) {
          JSONObject ResponseJson = parseJSONObject(response);
          JSONArray datas = ResponseJson.getJSONArray("datas");
          
          JSONObject data = null;
          if (datas.size() != 0) {
            for (int i = 0; i < datas.size(); i++) {
              data = datas.getJSONObject(i);
              int team = data.getInt("team");
              String sid = data.getString("sid");
              
              queue.put(team);
              if (team == 1) {
                achievement.attackTeamA(sid);
              } else {
                achievement.attackTeamB(sid);
              }
            }
            id = data.getInt("id");
          }
        }
      } catch (Exception e) {
        println("Exception: HttpConnect ApiData()");
        e.printStackTrace();
        StringWriter sw = new StringWriter();
        PrintWriter pw = new PrintWriter(sw);
        e.printStackTrace(pw);
        debug_log.append("[" + debug_format.format(Calendar.getInstance().getTime()) + "] Exception: " + sw.toString() + System.getProperty("line.separator"));
      }
    }
  }
}

//Extend original PostRequest with JSON Support
//https://forum.processing.org/two/discussion/12385/using-pushbullet-api-with-processing
// mostly from the httprequests-for-processing library
// header support added - acd 2015-09-05
 
import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map.Entry;
 
import org.apache.http.Header;
import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.NameValuePair;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.StringEntity;
import org.apache.http.entity.mime.MultipartEntity;
import org.apache.http.entity.mime.content.FileBody;
import org.apache.http.entity.mime.content.StringBody;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.message.BasicHeader;
import org.apache.http.message.BasicNameValuePair;
import org.apache.http.util.EntityUtils;
 
public class PostRequest {
  String url;
  ArrayList<BasicNameValuePair> nameValuePairs;
  HashMap<String, File> nameFilePairs;
  List<Header> headers;
 
  String content;
  String encoding;
  HttpResponse response;
  String json;
 
  public PostRequest(String url) {
    this(url, "ISO-8859-1");
  }
 
  public PostRequest(String url, String encoding) {
    this.url = url;
    this.encoding = encoding;
    nameValuePairs = new ArrayList<BasicNameValuePair>();
    nameFilePairs = new HashMap<String, File>();
    headers = new ArrayList<Header>();
  }
 
  public void addData(String key, String value) {
    BasicNameValuePair nvp = new BasicNameValuePair(key, value);
    nameValuePairs.add(nvp);
  }
 
  public void addJson(String json) {
    this.json = json;
  }
 
  public void addFile(String name, File f) {
    nameFilePairs.put(name, f);
  }
 
  public void addFile(String name, String path) {
    File f = new File(path);
    nameFilePairs.put(name, f);
  }
 
  public void addHeader(String name, String value) {
    headers.add(new BasicHeader(name, value));
  }
 
  public void send() {
    try {
      DefaultHttpClient httpClient = new DefaultHttpClient();
      HttpPost httpPost = new HttpPost(url);
 
      if (nameFilePairs.isEmpty()) {
        httpPost.setEntity(new UrlEncodedFormEntity(nameValuePairs, encoding));
      } else {
        MultipartEntity mentity = new MultipartEntity();    
        Iterator<Entry<String, File>> it = nameFilePairs.entrySet().iterator();
        while (it.hasNext ()) {
          Entry<String, File> pair =  it.next();
          String name = (String) pair.getKey();
          File f = (File) pair.getValue();
          mentity.addPart(name, new FileBody(f));
        }               
        for (NameValuePair nvp : nameValuePairs) {
          mentity.addPart(nvp.getName(), new StringBody(nvp.getValue()));
        }
        httpPost.setEntity(mentity);
      }
 
      // add the headers to the request
      if (!headers.isEmpty()) {
        for (Header header : headers) {
          httpPost.addHeader(header);
        }
      }
 
      // add json
      if (json != null) {
        StringEntity params =new StringEntity(json);
        //Comment due to "HTTP Error 400. The request has an invalid header name"
        //httpPost.addHeader("content-type", "application/x-www-form-urlencoded");
        httpPost.setEntity(params);
      }
 
      response = httpClient.execute( httpPost );
      HttpEntity   entity   = response.getEntity();
      this.content = EntityUtils.toString(response.getEntity());
 
      if ( entity != null ) EntityUtils.consume(entity);
 
      httpClient.getConnectionManager().shutdown();
 
      // Clear it out for the next time
      nameValuePairs.clear();
      nameFilePairs.clear();
    } catch( Exception e ) { 
      e.printStackTrace();
    }
  }
 
  /*
  ** Getters
  */
  public String getContent() {
    return this.content;
  }
 
  public String getHeader(String name) {
    Header header = response.getFirstHeader(name);
    if (header == null) {
      return "";
    } else {
      return header.getValue();
    }
  }
}
