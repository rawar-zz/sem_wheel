import java.net.URLEncoder;

/**
* Search wrapper class for co2alarm.com search queries.
*
* @author  Ramon Wartala (ramon@wartala.de) 
*/
public class Co2alarmSearch {
  
  private ArrayList searchResults;
  
  Co2alarmSearch() {
    searchResults = new ArrayList();
  }
  
  ArrayList getPersons(int minFreq) {
    ArrayList persons = new ArrayList();
    Iterator iter2 = searchResults.iterator();
    while(iter2.hasNext()) {
      Co2alarmTerm term = (Co2alarmTerm) iter2.next();
      if(term.count >= minFreq && term.type.equals("PERSON") && !term.text.equals("Obama")) {
        println("\t"+term.toString());
        persons.add(term);
      }
    }
    return persons;
  }
  
  ArrayList getWithoutPersons(int minFreq) {
    ArrayList terms = new ArrayList();
    Iterator iter2 = searchResults.iterator();
    while(iter2.hasNext()) {
      Co2alarmTerm term = (Co2alarmTerm) iter2.next();
      if(term.count >= minFreq && !term.type.equals("PERSON")) {
        terms.add(term);
      }
    }
    return terms;
  }
  
  ArrayList getResults(int minFreq) {
    ArrayList terms = new ArrayList();
    Iterator iter2 = searchResults.iterator();
    while(iter2.hasNext()) {
      Co2alarmTerm term = (Co2alarmTerm) iter2.next();
      if((term.count >= minFreq && term.type.equals("COMMON NOUN")) || term.type.equals("ORGANIZATION") || term.type.equals("COMPANY") || term.type.equals("ORGANIZATION") || term.type.equals("CITY") || term.type.equals("COUNTRY")) {
        println("\t"+term.toString());
        terms.add(term);
      }
    }
    return terms;
  }
  
  ArrayList getResults(int minFreq, ArrayList persons) {
    ArrayList terms = new ArrayList();
    Iterator iter2 = searchResults.iterator();
    while(iter2.hasNext()) {
      Co2alarmTerm term = (Co2alarmTerm) iter2.next();
      if((term.count >= minFreq && term.type.equals("COMMON NOUN")) || term.type.equals("ORGANIZATION") || term.type.equals("COMPANY") || term.type.equals("ORGANIZATION") || term.type.equals("CITY") || term.type.equals("COUNTRY")) {
        println("\t"+term.toString());
        terms.add(term);
      }
    }
    
    Iterator iter3 = persons.iterator();
    while(iter3.hasNext()) {
      Co2alarmTerm person = (Co2alarmTerm) iter3.next();
      terms.add(person);
    }
    
    return terms;
  }
  
  void doSearch(String query) {
    searchResults.clear();
    
    //String encodedQuery = java.net.URLEncoder.encode(query);
    String encodedQuery = clearSpaceInURL(query);
    //println("encoded query: "+encodedQuery);
    String url = "http://www.co2alarm.com/sem_wheel/search_all/"+encodedQuery+".json";
    JSONObject result = pullJSON(url);
    
    Iterator iter = result.keys();
    try {
      while(iter.hasNext()) {
        String term = (String) iter.next();
        if(!term.equals("")) {
          JSONArray  term_value = result.getJSONArray(term);
          int freq = term_value.getInt(2);
          String type = term_value.getString(1);
          String text = term_value.getString(0);
          text = text.replace(".","");
          Co2alarmTerm rterm = new Co2alarmTerm(text, freq, type);
          //println(rterm.toString());
          searchResults.add(rterm);
        }
      }
    } catch(JSONException je) {
      println(je.toString());
    }    
  }
  
  /**
  * Search only Person terms.
  *
  * @deprecated
  */
  ArrayList doPersonSearch(String query, int minTermFreq) {
    ArrayList tlist = new ArrayList();
    String encodedQuery = java.net.URLEncoder.encode(query);
    String url = "http://www.co2alarm.com/sem_wheel/search_persons/"+encodedQuery+".json";
    JSONObject persons = pullJSON(url);
    
    Iterator iter = persons.keys();
    try {
      while(iter.hasNext()) {
        String person = (String) iter.next();
        JSONArray  person_term = persons.getJSONArray(person);
        int freq = person_term.getInt(2);
        String person_str = person_term.getString(0);
        person_str = person_str.replace(".","");
        //println("person:"+person_str+"="+freq);
        if(!person_str.equals("Obama")) {
          tlist.add(new Co2alarmTerm(person_str, freq, "PERSON"));
        }
      }
    } catch(JSONException je) {
      println(je.toString());
    }
    
    Iterator iter2 = tlist.iterator();
    while(iter2.hasNext()) {
      Co2alarmTerm term = (Co2alarmTerm) iter2.next();
      if(term.count < minTermFreq) {
        iter2.remove();
      }
    }
    
    return tlist;
  }
  
  /**
  * Search terms.
  *
  * @deprecated
  */
  ArrayList doTermSearch(String query, int minTermFreq, ArrayList persons) {
    ArrayList tlist = new ArrayList();
    String encodedQuery = java.net.URLEncoder.encode(query);
    String url = "http://www.co2alarm.com/sem_wheel/search_nouns/"+encodedQuery+".json";
    JSONObject terms;
    terms = pullJSON(url);
    //println(terms.toString());
    Iterator iter = terms.keys();
    tlist.clear();
    try {
      while(iter.hasNext()) {
        String term = (String) iter.next();
        JSONArray noun_term = terms.getJSONArray(term); 
        int freq = noun_term.getInt(2);
        String type = noun_term.getString(1);
        String text = noun_term.getString(0);
        //println("term:"+term+"="+freq);
        tlist.add(new Co2alarmTerm(text, freq, type));
      }
    } catch(JSONException je) {
    }
    
    //println("person is '"+query+"'");
    
    Iterator iter2 = tlist.iterator();
    while(iter2.hasNext()) {
      Co2alarmTerm term = (Co2alarmTerm) iter2.next();
      if((term.count <= minTermFreq && term.type.equals("COMMON NOUN")) || term.type.equals("CITY") || term.type.equals("ORGANIZATION") ) {
      //if((term.count <= minTermFreq && term.type.equals("COMMON NOUN")) || (term.type.equals("ORGANIZATION"))) {
        iter2.remove();
      } else {
        println("\tuse term '"+term.text+"' ("+term.type+"):"+term.count);
      }
    }
    
    if(persons != null) {
      Iterator iter3 = persons.iterator();
      while(iter3.hasNext()) {
        Co2alarmTerm person = (Co2alarmTerm) iter3.next();
        tlist.add(person);
      }
    }
    
    return tlist;
  }
  
  /**
  * JSON communication methode.
  *
  * @param targetURL the JSON endpoint URL.
  */
  JSONObject pullJSON(String targetURL) {
   String jsonTxt = "";   
   JSONObject retVal = new JSONObject();
   InputStream  in = null;              
   
   try {
      URL url = new URL(targetURL);        
      in = url.openStream();                 
      byte[] buffer = new byte[8192];
      int bytesRead;
      while ( (bytesRead = in.read(buffer)) != -1) {
         String outStr = new String(buffer, 0, bytesRead);
         jsonTxt += outStr;
      }
      in.close();
   } catch (Exception e) {
      System.out.println (e);
   }
   
   try {
      retVal = new JSONObject(jsonTxt);
   } catch (JSONException e) {
     println ("Co2alarmSeach: pullJSON():"+e.toString());
   }
   return retVal;  
  }
  
  /**
  * Helper methode to encode white spaces between strings
  *
  * @param url original URL string.
  */
  String clearSpaceInURL(String url) {
    String encodedURL = url;
    encodedURL = encodedURL.replaceAll(" ", "%20");
    return encodedURL;
  }    
}

