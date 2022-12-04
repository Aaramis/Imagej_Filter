/* HomeWork
*
* Auguste GARDETTE IODAA - AMI2B
*
* OBJECTIFS : 
*
* ImageJ macro testing a user-selected filter (from a list) on an image and applying it to a user-defined radian range.
*/

// Optimisation & Security
run("Close All");
setBackgroundColor(0, 0, 0);
// setBatchMode(true); //batch mode on


// 1: Get an image from user

waitForUser("Please open image")
open();
rename("The_image");
// dir_out=getDirectory("Please choose a directory")

// For testing - Get a random image to do the test
// blobsFile = getDirectory("startup")+"samples"+File.separator+"blobs.gif";
// blobsFile = "/atHome/ImageJ Developer/testimages/blobs.gif";
// if (File.exists(blobsFile))
//   open(blobsFile);
// else
//   run("Blobs (25K)");

// 2: Get parameters choices from user:

var filter_choice;
var min;
var max;
var increment;
list_filters= newArray("Gaussian Blur", "Median", "Mean", "Minimum", "Maximum", "Unsharp Mask", "Variance", "Top Hat");

function swap_if_inferior(){
  // Swap variables min max
  var temp;
  if (min > max) {
    temp = min;
    min = max;
    max = temp;
  };
};

function user_choice() {
  Dialog.create("SETUP");
  Dialog.addMessage("Filter", 18);
  Dialog.addRadioButtonGroup("", list_filters,lengthOf(list_filters),1,list_filters[0]);
  Dialog.addMessage("Radius", 18);
  Dialog.addNumber("Min", 2);
  Dialog.addNumber("Max", 5);
  Dialog.addNumber("Increment", 1);
  Dialog.show();
  filter_choice = Dialog.getRadioButton;
  min = Dialog.getNumber;
  max = Dialog.getNumber;
  increment = Dialog.getNumber;
  swap_if_inferior();
};

while (increment <= 0 || min < 0){
  user_choice();
}


// 3: Filtration for each radius, calculation & saving :

function Entropy(histogram, area){
  var value;
  value = 0;
  for (i = 0; i < histogram.length; i++){
    if (histogram[i] > 0){
      value += ((histogram[i]/area) * (Math.log(histogram[i]/area)/Math.log(2)));
    }
  }
  return -value
}

imageID = newArray((max - min) / increment);
Cm_lst = newArray((max - min) / increment);
SNR_lst = newArray((max - min) / increment);
H_lst = newArray((max - min) / increment);
Radius_lst = newArray((max - min) / increment);


rename("The_image");
j = 0;
for (i = min; i <= max; i += increment){
  imageID[j] = getImageID();
  selectImage(imageID[0]);
  run("Duplicate...", "title=Radius_"+i);
  run(filter_choice + "...", "radius="+i);
  getStatistics(area, mean, min_2, max_2, std, histogram);
  Cm_lst[j] = (max_2 - min_2) / (max_2 + min_2);                  // Michelson contrast (Cm) 
  if (std != 0) {
    SNR_lst[j] = 10 * Math.log(((mean/std)^2))/Math.log(10);        // SNR Statistical (SNRstat) in db
  }
  else {
    SNR_lst[j] = 0;
  }
  H_lst[j] = Entropy(histogram, area);                            // Entropy (H)
  Radius_lst[j] = i;
  j++;
}

run("Tile"); // Mosaic ?

// 4: Graphs Generation (on the same document)

function min_lst(list){
  value = 1000000;
  for (i = 0; i < list.length; i++){
    if (list[i] < value) {
      value = list[i];
    }
  }
  return value;
}

function max_lst(list){
  value = 0;
  for (i = 0; i < list.length; i++){
    if (list[i] > value) {
      value = list[i];
    }
  }
  return value;
}

function check_na(list){
  for (i = 0; i < list.length; i++){
    if (isNaN(list[i])){
      return true
    }
  }
  return false
}

value_min = min_lst(SNR_lst);
if (value_min > min_lst(Cm_lst)) {
  value_min = min_lst(Cm_lst);
}
if (value_min > min_lst(H_lst)) {
  value_min = min_lst(H_lst);
}
if (value_min < -10) {
  value_min = -10;
}

value_max = max_lst(SNR_lst);
if (value_max < max_lst(Cm_lst)) {
  value_max = max_lst(Cm_lst);
}
if (value_max < max_lst(H_lst)) {
  value_max = max_lst(H_lst);
}

Plot.create("Cm, SNR, H (Radius)", "Radius", "Y");
Plot.setLimits(min, max, value_min - 0.2, value_max + 0.2);
Plot.setColor("green");
Plot.setLineWidth(2)
Plot.add("line", Radius_lst, SNR_lst, "SNR");                 // SNR Statistical (SNRstat)
Plot.setColor("red");
Plot.add("line", Radius_lst, Cm_lst, "Cm");                   // Michelson contrast (Cm) 
Plot.setColor("blue");
Plot.add("line", Radius_lst, H_lst, "H");                     // Entropy (H)
Plot.setAxisLabelSize(14, "bold");
Plot.setLegend("", "top-right");
Plot.show;

// Optimisation & Security
setBatchMode(false); //exit batch mode