/**
* Store the term structure
*
* @author  Ramon Wartala (ramon@wartala.de)
*/
public class Co2alarmTerm {
  private String text;
  private int count;
  private String type;
  
  Co2alarmTerm(String text, int count, String type) {
    this.text = text;
    this.count = count;
    this.type = type;
  } 
  
  String getText() {
    return this.text;
  }
  
  int getCount() {
    return this.count;
  }
  
  String getType() {
    return this.type;
  }
  
  String toString() {
    return text+" ("+type+")="+count;
  }
}

