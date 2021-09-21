// Outil pour enlever une étiquette
// Outil Tout remettre à zéro
// LUT : 254 rouge 255 vert
// sauvegarder/charger un projet
// inverser la contour map pour cellule mitose par ex

// Constants
var nMax = 253; // 254 and 255 are reserved labels
var objLabel = 254;
var bgLabel = 255;

// Parameters
var brushWidth = 10;
var opacity = 40;
var adjustBC = true;
var lut = "iWatershedSeg-black-red-green";
var invertContourMap = false;

// Global variables for current project
var image = 0;
var contourMap = 0;
var labels = 0;
var objectCount = 0;
var currentFrame = 1;
var nFrames = 1;
var brushType = objLabel;


//macro "Unused Tool-1 - " {}

macro "Setup_project Action Tool - C059 T8c14S"
{
	proj = newArray("start a new project", "load a project");
	Dialog.create("Interactive Watershed Segmentation");
	Dialog.addChoice("Project:", proj, proj[0]);
	Dialog.show();
	opt = Dialog.getChoice();

	if (opt == proj[0]) // newProjectDialog()
	{
		setUpGlobalVar();
		imgs = getImageList();
		
		Dialog.create("Interactive Watershed Segmentation");
		Dialog.addChoice("Image to be segmented:", imgs);
		Dialog.addChoice("Contour map for watershed algorithm:", imgs);
		Dialog.show();
	
		img1 = Dialog.getChoice();
		selectWindow(img1);
		image = getImageID();
		Stack.getDimensions(width, height, channels, slices, nFrames);
		print(width, height, channels, slices, nFrames);
		Stack.getPosition(channel, slice, currentFrame);
		// check if channels == 1 sinon erreur
		
		img2 = Dialog.getChoice();
		selectWindow(img2);
		contourMap = getImageID();
	
		// Create the storage for labels
		// First slice: markers for watershed
		// Second slice: watershed segmentation
		// Third slice: registered objects
		newImage("labels", "8-bit grayscale-mode", width, height, 3, slices, nFrames);
		labels = getImageID();
		run(lut);
		updateOverlay();
	}
	else // loadProjectDialog 
	{
		exit("not yet supported");
	}
}

macro "Brush_Object Tool - Ce00 La077 Ld098 L6859 L4a2f L2f4f L3f99 L5e9b L9b98 L6888 L5e8d L888c"
{
	brushType = objLabel;
	draw();
}

macro "Brush_Object Tool Options"
{
	setBrushWidth();
}

macro "Brush_Background Tool - Ce00 La077 Ld098 L6859 L4a2f L2f4f L3f99 L5e9b L9b98 L6888 L5e8d L888c"
{
	brushType = bgLabel;
	draw();
}

macro "Brush_Background Tool Options"
{
	setBrushWidth();
}

macro "Eraser Tool - Ce00 La077 Ld098 L6859 L4a2f L2f4f L3f99 L5e9b L9b98 L6888 L5e8d L888c"
{
	brushType = 0;
	draw();
}

macro "Eraser Tool Options"
{
	setBrushWidth();
}

macro "Segment Action Tool - C059 T8c14S"
{
	segment();
}

macro "Register_object Action Tool - C059 T8c14R"
{
	registerCurrentObject();
}

macro "Previous_frame Action Tool - C059 T8c14<"
{
	setBatchMode(true);
	currentFrame--;
	setCurrentFrame(image);
	setCurrentFrame(labels);
	updateOverlay();
	setBatchMode("exit and display");
}

macro "Next_frame Action Tool - C059 T8c14>"
{
	setBatchMode(true);
	currentFrame++;
	setCurrentFrame(image);
	setCurrentFrame(labels);
	updateOverlay();
	setBatchMode("exit and display");
}

macro "More Action Tool - C059 T8c14M"
{
	more = newArray("Project parameters", "Reset current object segmentation", 
	"Remove a registered object", "Jump to frame", "Save current project");
	Dialog.create("More actions");
	//Dialog.addRadioButtonGroup("", more, more.length, 1, more[0]);
	Dialog.addChoice("", more, more[0]);
	Dialog.show();
}

function resetCurrentLabel()
{
	selectImage(labels);
	for (i = 1; i < 3; i++)
	{
		Stack.setChannel(i);
		run("Select None");
		run("Set...", "value=0 slice");
	}
}

function setUpGlobalVar()
{
	image = 0;
	contourMap = 0;
	labels = 0;
	objectCount = 0;
	currentFrame = 1;
	nFrames = 1;
	brushType = objLabel;
}

// setParameters
/*
var brushWidth = 10;
var opacity = 40;
var adjustBC = true;
var lut = "iWatershedSeg-black-red-green";
var invertContourMap = false;
*/
function setBrushWidth()
{
	Dialog.create("Brush width");
	Dialog.addSlider("Brush width:", 1, 100, brushWidth);
	Dialog.show();
}

function updateOverlay()
{
	setBatchMode(true);
	setCurrentFrame(image);
	name = getTitleByID(image);
	resetMinAndMax();
	if (adjustBC) run("Enhance Contrast", "saturated=0.35");
	setCurrentFrame(labels);
	run("Remove Overlay");
	for (i = 1; i < 4; i++)
	{
		Stack.setChannel(i);
		run("Add Image...", "image=&name x=0 y=0 opacity=&opacity");
	}
	setBatchMode("exit and display");
}

function getTitleByID(id)
{
	selectImage(id);
	return getTitle();
}

function setCurrentFrame(img)
{
	selectImage(img);
	if (nFrames > 1) Stack.setFrame(currentFrame);
}

function getImageList()
{
	count = nImages();
	if (count == 0) return -1; // error()

	setBatchMode(true);
	currentID = getImageID();
	id = newArray(count);
	names = newArray(count);
	for (i = 0; i < count; i++)
	{
		selectImage(i + 1);
		id[i] = getImageID();
		names[i] = getTitle();
	}
	selectImage(currentID);
	setBatchMode(false);

	return names;
}

function draw()
{
	if (labels == 0)
	{
		exit("error message");
	}
	setColor(brushType);
	setCurrentFrame(labels);
	selectImage(labels);
	Stack.setChannel(1);
    leftClick = 16;
    getCursorLoc(x, y, z, flags);
    setLineWidth(brushWidth);
    moveTo(x,y);
    x2 = -1; y2 = -1;
    while (true)
    {
        getCursorLoc(x, y, z, flags);
        if (flags & leftClick == 0) exit();
        if (x != x2 || y != y2) lineTo(x, y);
        x2 = x; y2 = y;
        wait(10);
    }
}

function segment()
{
	// Vérifier qu'il ya bien les deux étiquettes présentes
	
	// stocker le current frame pour éviter les erreurs
	setBatchMode(true);

	// Create markers
	selectImage(labels);
	run("Select None");
	run("Duplicate...", "duplicate channels=1 frames=&currentFrame");
	tmp1 = getTitle();
	run("Duplicate...", "duplicate channels=3 frames=&currentFrame");
	tmp2 = getTitle();
	imageCalculator("Max create stack", tmp1, tmp2);
	markers = getTitle();
	changeValues(1, nMax, bgLabel);
	close(tmp1);
	close(tmp2);

	// Watershed segmentation
	selectImage(contourMap);
	run("Duplicate...", "duplicate frames=&currentFrame");
	cmap = getTitle();
	if (invertContourMap) run("Invert", "stack");
	run("Marker-controlled Watershed", "input=&cmap marker=&markers mask=None calculate use");
	seg = getTitle();
	selectImage(labels);
	Stack.setChannel(2);
	imageCalculator("Copy", labels, seg); // Ne gère pas la 3D

	close(markers);
	close(cmap);
	close(seg);

	setBatchMode("exit and display");
}

function pixelSelection(value)
{
	setThreshold(value, value);
	run("Create Selection");
}

function registerCurrentObject()
{
	// Vérifier qu'il ya bien les deux étiquettes présentes
	if (objectCount <= nMax)
	{
		setBatchMode(true);
		objectCount++;
		selectImage(labels);
		Stack.setChannel(2);
		pixelSelection(objLabel);
		Stack.setChannel(3);
		run("Set...", "value=&objectCount slice"); // 3D pas gérée
		resetCurrentLabel();
		Stack.setChannel(3);
		setBatchMode("exit and display");
	}
	else 
	{
		exit("Maximum number of objects is reached.");
	}
}
