/**
* Store the link structure
*
* @author  Ramon Wartala (ramon@wartala.de)
*/
public class Co2alarmLink {
  
  Co2alarmTerm term;
  ArrayList links;
  float x;
  float y;
  
  float xin;
  float yin;
  
  float xin2;
  float yin2;
  
  float xout;
  float yout;
  color c;
  boolean positioned;
  int linklevel;
  int linkcount;
  
  Co2alarmLink(Co2alarmTerm t) {
    this.term = t;
    links = new ArrayList();
    positioned = false;
    linkcount = 0;
  }
}
