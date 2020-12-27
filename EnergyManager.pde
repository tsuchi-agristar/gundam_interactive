public class EnergyManager
{
  public ArrayList<Energy> energylist;

  public EnergyManager() {
    energylist = new ArrayList<Energy>();
  }
  
  public void setEnergy(int team) {
    float start_x, start_y, end_x, end_y;
    
    //A Team
    if (team == 1) {
      start_x = energy_ball_start_a_x;
      start_y = energy_ball_start_a_y;
      end_x   = energy_ball_end_a_x;
      end_y   = energy_ball_end_a_y;
      //random
      start_x += random(-400, 600);
      start_y += random(-50, 50);
      end_x   += random(-15, 15);
      end_y   += random(-15, 15);
    }
    //B Team
    else {
      start_x = energy_ball_start_b_x;
      start_y = energy_ball_start_b_y;
      end_x   = energy_ball_end_b_x;
      end_y   = energy_ball_end_b_y;
      //random
      start_x += random(-600, 400);
      start_y += random(-50, 50);
      end_x   += random(-15, 15);
      end_y   += random(-15, 15);
    }
    
    int image_length = energy_images;
    image_length += (int) random(0, 5);

    Energy energy = new Energy(start_x, start_y, end_x, end_y, image_length);
    energylist.add(energy);
  }
  
  public void energyDraw() {
    try {
      for (Energy energy : energylist) {
        energy.draw();
      }
      
      Iterator<Energy> iterator = energylist.iterator();
      while (iterator.hasNext()) {
        Energy energy = iterator.next();
        if (!energy.status()) {
          iterator.remove();
        }
      }
    } catch (Exception e) {
      println("Exception: EnergyManager energyDraw()");
      e.printStackTrace();
      //just in case
      energylist = new ArrayList<Energy>();
    }
  }
}

public class Energy
{
  private float start_x, start_y, end_x, end_y;
  private int image_length;
  private int current = 0;
  
  public Energy(float start_x, float start_y, float end_x, float end_y, int image_length) {
    this.start_x = start_x;
    this.start_y = start_y;
    this.end_x = end_x;
    this.end_y = end_y;
    this.image_length = image_length;
  }
  
  public void draw() {
    try {
      float pos_x = start_x + (end_x - start_x) / image_length * current;
      float pos_y = start_y + (end_y - start_y) / image_length * current;
      imageMode(CENTER);
      image(energy_img, pos_x, pos_y, energy_img.width * energy_size_ratio, energy_img.height * energy_size_ratio);
      imageMode(CORNER);

      current++;
    } catch (Exception e) {
      println("Exception: Energy draw()");
      e.printStackTrace();
    }
  }
  
  public boolean status() {
    return current < image_length;
  }
}
