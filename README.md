# Making Animated Anchored Mural Elements

This document is aimed at explaining some of the existing interactions available in the app. There is more development on the way that will support adding in new images, but for now we have an already installed set which will work in the space

## General process

An animated layer is created in the following steps,
* For each mural element
    * Place animated element over their corresponding static real world element
    * Resize/Reposition to suit 
    * "Anchor" the element to ensure it's placement stays when someone else loads the experience later
* Generate a virtual background to prevent confusion
    * place the 4 furthest points (making a bounding box)
    * add the intermediate points that help "cut out" real world objects you don't want masked
    * select 3 points to make a "triangle" of virtual background 
    * repeat until the rest of the mural is hidden
    * modify any points who's texture looks incorrect
    * "Anchor" the points  so it will automatically appear on reload

The rest of the document exists to explain "How" to perform these steps in the application with the right quest 3 controller

## Types of interaction

### Placing Elements



### 

## Tips