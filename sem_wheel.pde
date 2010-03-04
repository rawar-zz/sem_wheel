/**
 * sem_wheel - semantic wheel sketch for co2alarm.com
 * 
 * Visualize co2alarm.com JSON-based search results with Processing.
 * Based on Jer Thorp (blprnt@blprnt.com) work with NYTimes search results. 
 * See more at http://blog.blprnt.com/blog/blprnt/7-days-of-source-day-2-nytimes-36536
 *
 * @author  Ramon Wartala (ramon@wartala.de)
 * @version 0.1
 */

import toxi.math.noise.*;
import toxi.math.waves.*;
import toxi.geom.*;
import toxi.math.*;
import toxi.math.conversion.*;
import toxi.geom.util.*;

import org.json.*;
import java.util.ArrayList;
import java.util.AbstractCollection;
import processing.pdf.*;

PFont font;                                        // The display font
HashMap links = new HashMap();                     // HashMap to store all of the link objects
ArrayList linkArray = new ArrayList();             // ArrayList to store all of the link objects
HashMap localMaxes = new HashMap();                // HashMap to store the search totals for individual links
String mainQuery = "carbon dioxid";                // main query
String outputFileName = mainQuery+"-sketch.pdf";   // PDF file name
Vec2D center;                                      // 2D Vector to store center point of graphic

// Colour list for multi-color version
color[] colors = {#C9313D,#F9722E,#CDD452,#375D81,#B8CC00,#142601,#668C14,#F28705,#A3140F,#183152};

// Single colour for monochrome version
color mainColor;

// different term types 
String[] linkFacets = {
  "PERSON", "COMPANY", "COMMON NOUN", "ORGANIZATION", "CITY", "COUNTRY"};

void setup() {
  
  // Load font for text display
  font = createFont("Meta-Normal", 100); 
  textFont(font); 

  // Define the PDF output
  size(3000, 3000, PDF, outputFileName);
  center = new Vec2D(width/2, height/2);
  smooth();
  
  // Links to store the terms
  links = new HashMap();
  linkArray = new ArrayList();
  localMaxes = new HashMap();
  
  // Paint a light green background
  background(227,255,245);
  
  // For monochromes, pick a random base colour  
  mainColor = color(random(150),random(150),random(150));
  
  // Draw the semantic wheel by given query string
  drawSemWheel(mainQuery);
  
  println("finish!");
}

/**
 * Draw the semantic wheel from a search result given by co2alarm.com
 * 
 * @param query  the search query. If the query string is null, nothing is drawn.
 */
void drawSemWheel(String query) {
  println("search co2alarm.com for persons who has a relationship to '"+query+"'...");
  
  // creates an search object 
  Co2alarmSearch search = new Co2alarmSearch();
  search.doSearch(query);
  // get all person names with x count from search results
  ArrayList persons = search.getPersons(2);
  
  println("OK");
  
  // set up local maxes
  // the MaxObject Class is defined at the bottom of the tab.
  for (int j = 0; j < linkFacets.length; j++) {
    localMaxes.put(linkFacets[j], new MaxObject(0));
  };
  
  // create a link object in the links hashtable for each one
  for(int i = 0; i < persons.size(); i++) {
    Co2alarmTerm t = (Co2alarmTerm) persons.get(i);
    MaxObject mo = (MaxObject) localMaxes.get(t.type);
    localMaxes.put(t.type, new MaxObject(max(mo.maxi, t.count)));
    Co2alarmLink lo = new Co2alarmLink(t);
    lo.linklevel = 0;
    if (links.get(t.text) == null) {
      links.put(t.text, lo);
      linkArray.add(i, lo);
    };  
  }
  
  // run through the links array again and find the links for each new facet
  for(int i = 0; i < persons.size(); i++) {
    Co2alarmTerm person = (Co2alarmTerm) persons.get(i);
    // new query with person and term
    String newQuery = query+" "+person.text;
    println("search terms for '"+newQuery+"'...");
    
    Co2alarmSearch search2 = new Co2alarmSearch();    
    search2.doSearch(newQuery);
    ArrayList linkTerms = search2.getResults(7, persons);
    
    println("OK");
    
    for (int j=0; j < linkTerms.size(); j++) {
      Co2alarmTerm t2 = (Co2alarmTerm) linkTerms.get(j);
      Co2alarmLink l2 = new Co2alarmLink(t2);  
      if (links.get(t2.text) == null) {
        links.put(t2.text, l2);
        l2.linklevel = 1;
      }
      else {
        // facet already exists
        Co2alarmLink ll = (Co2alarmLink) links.get(t2.text);
        ll.linkcount ++;
      };
    };
    
    Co2alarmLink l = (Co2alarmLink) linkArray.get(i);
    l.links = linkTerms;
  }
  
  // draw the text nodes
  println("draw nodes");
  drawNodes();
  
  // draw the bezire links
  println("draw links");
  drawLinks();

  // draw the query text on the left side
  int ts = 150;
  fill(128,179,69);
  textFont(font);
  textSize(ts);
  float w = textWidth(query);
  float h = ts;
  text(query, 75,160);
}

/**
* Draw the links between the term nodes
*
*/
void drawLinks() {
  
  for (int i = 0; i < linkArray.size(); i++) {
    //Draw main
    color c;
    Co2alarmLink l = (Co2alarmLink) linkArray.get(i);
    for (int j = 0; j < l.links.size(); j++) {
      Co2alarmTerm to = (Co2alarmTerm) l.links.get(j);
      Co2alarmLink l2 = (Co2alarmLink) links.get(to.text);
      c = color(red(l.c), green(l.c), blue(l.c), alpha(l.c));
      stroke(c, 100);
      noFill();
      
      // l2 = outer term, l = person term
      if (l2.linklevel == 0 && l.linklevel == 0) {
        // If both of the links are central, use the middle point as a control
        beginShape();
        vertex(l.x, l.y);
        bezierVertex(l.x, l.y, center.x, center.y, l2.x, l2.y);
        endShape();
      }
      else {
        // Otherwise, use the out point of the second link as the control
        c = color(red(l.c), green(l.c), blue(l.c), alpha(l.c)/2);
        stroke(c, 100);
        beginShape();
        vertex(l.xin, l.yin);
        bezierVertex(l.xin2, l.yin2, l.xout, l.yout, l2.x, l2.y);
        endShape();
      };
    };
  };
};

/**
* Draw the term nodes
*
*/
void drawNodes() {
  
  float ct = PI;
  float cti = (PI * 2) / links.size();
  //First, run through the main list of links, and position them around a centre point
  //Also, put their subsidiary links out
  
  int i;
  float t = PI/2;
  float ti = (PI*2)/linkArray.size();
  float rad = 175;
  float x;
  float y;
  MaxObject lm;
  for (i = 0; i < linkArray.size(); i++) {
    //Draw main
    x = center.x + (sin(t) * rad * 2);
    y = center.y + (cos(t) * rad * 2);
    
    float xout = center.x + (sin(t) * rad * 4);
    float yout = center.y + (cos(t) * rad * 4);
     
    Co2alarmLink l = (Co2alarmLink) linkArray.get(i);
    
    lm = (MaxObject) localMaxes.get(l.term.type);
    float f = float(l.term.count) / lm.maxi;
    //float f = float(l.term.count) / 20;
    
    textFont(font);
    textSize(32 + (40 * f));
    
    float sl = textWidth(l.term.text) + 10;
    float xin = center.x + (sin(t) * ((rad * 2) + sl));
    float yin = center.y + (cos(t) * ((rad * 2) + sl));
    
    //Link objects have in and out points, both X and Y. This means that connections go into a link at one spot and out of a link at the other.
    //For these outer links, the in points are at the front of the text, and the out points are at the end of the text.
    l.x = x;
    l.y = y;
    l.xout = xout;
    l.yout = yout;
    l.yin = yin;
    l.xin = xin;
    l.xin2 = center.x + (sin(t) * ((rad * 2) + sl + 200));
    l.yin2 = center.y + (cos(t) * ((rad * 2) + sl + 200));
    
    l.positioned = true;
    
    // set alpha and colour
    float a = 255 - (100 + (f * 155));
    float ca = 0.2;
    
    // here we choose a random colour from our colour list
    l.c = colors[i % 10];
    
    //Moce to the correct position
    pushMatrix();
    translate(x,y);
    rotate(-t + (PI/2));
    fill(l.c);
    //Draw the text.
    text(l.term.text, 4, 6);
    popMatrix();
    
    //Draw subsidiaries
    //This is the same process as with the inner ones, but they don't have separate in and out points.
    for (int j = 0; j < l.links.size(); j++) {
      float j2 = float(j);
      float frac = (j2 / float(l.links.size()));
      float t2 = t + (frac * ti * 1);
      
      Co2alarmTerm fo = (Co2alarmTerm) l.links.get(j);
      Co2alarmLink l2 = (Co2alarmLink) links.get(fo.text);

      x = center.x + (sin(ct) * (rad - (l2.linkcount * 2)) * 6.5);
      y = center.y + (cos(ct) * (rad - (l2.linkcount * 2)) * 6.5);
      
      if (l2 != null && !l2.positioned && l2.linklevel > 0) {

        l2.x = x;
        l2.y = y;
        l2.positioned = true;

        //Size and colour of text is dependant on how many results the search term returns.
        //To keep this balanced (we don't want text to be too big or small), it's weighted against the maximum results that any given term returned.
        lm = (MaxObject) localMaxes.get(l2.term.type);
        float cf = float(l2.term.count) / lm.maxi;
        //float cf = float(l2.term.count) /  12;
        l2.c = color( 200 - ((55 + (cf * 200)) * 2));

        pushMatrix();
          translate(x,y);
          rotate(-ct + (PI/2));
          fill(l2.c);
          textSize(min(4 + (200 * cf) + (l2.linkcount *2),26));
          text(l2.term.text, 4, 6);
        popMatrix();
        

      };
      ct -= cti;
    };



    t += ti;
  };
};

public class MaxObject {
  int maxi; 
  MaxObject(int m) {
    maxi = m;
  };
}
