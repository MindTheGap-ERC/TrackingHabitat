function stacker
% Code for Stacker a simple numerical forward model to explore Walther's Law
% Written by P Burgess, University of Liverpool
% Started 4/8/2018 Latest updates May 2023

    clear all;
    
    
    gui.main = 0;
    gui.f1 = 0;
    
    [params, strata run] = initialiseVariables;
    initializeGUI(gui, params, run, strata);
end

function [params, strata run] = initialiseVariables

    params.loaded = 0;    % Boolean flag to show if data loaded or not; if not, subsequent functions disabled
    params.initialised = 0;
    params.modelName = '';
    params.gridCellsX = 0;
    params.gridCellsY = 0;
    params.gridDx = 0;
    params.gridDy = 0;
    params.totalEMT = 0.0;
    params.deltaT = 0.0;
    params.initialBathymetryFname = '';
    params.initialBathymetryMap = zeros(params.gridCellsY, params.gridCellsX);
    params.subsidenceRate = 0.0;
    params.sealevelCurveFname = '';
    params.sealevelCurve = zeros(1,1);
    params.modelType = '';
    
    strata.layers = zeros(1,1);
    strata.facies = zeros(1,1);
    
    run.totalIterations = 0;

end

function initializeGUI(gui, params, run, strata)

    % ScreenSize is a four-element vector: [left, bottom, width, height]:
    scrsz = get(0,'ScreenSize'); % vector 
    
    %% Create the main graphics window, with the vertical section plot, a selection of other output, and the main buttons and text parameter inputs
    scrWidthProportion = 0.75;
    scrHeightIncrement = scrsz(4)/20; % Use this to space controls down right side of the main window
    controlStartY = (scrsz(4) * 0.8) - (scrHeightIncrement / 2);
    controlStartX = (scrsz(3) * scrWidthProportion) - 420;
    
    % position requires left bottom width height values. screensize vector
    % is in this format 1=left 2=bottom 3=width 4=height
    % Hide the window as it is constructed by setting visible to off
    gui.main = figure('Visible','off','Position',[1 scrsz(4)*scrWidthProportion scrsz(3)*scrWidthProportion scrsz(4)*0.8]);
       
   %  Construct the control panel components.
   hParamsFpathLabel = uicontrol('style','text','string','Parameters file path:','Position',[controlStartX+40, controlStartY-scrHeightIncrement, 200, 15]);
   hParamsFpath = uicontrol('Style','edit','String','parameters/','Position',[controlStartX+200, controlStartY-scrHeightIncrement, 200, 25]);
   
   hParamsFnameLabel = uicontrol('style','text','string','Parameters filename:','Position',[controlStartX+40, (controlStartY-scrHeightIncrement*2), 200, 15]);
   hParamsFname = uicontrol('Style','edit','String','stackerFaciesMosaic.txt','Position',[controlStartX+200, (controlStartY-scrHeightIncrement*2), 200, 25]);
   
   hLoadParamsFile = uicontrol('Style','pushbutton','String','Load parameter file',...
          'Position',[controlStartX+200,controlStartY-(scrHeightIncrement*4),200,25],...
          'BackgroundColor',[0.6 1.0 0.6],...
          'Callback',{@loadParameterFile_callback});
      
   hInitialiseModel = uicontrol('Style','pushbutton','String','Initialise model',...
          'Position',[controlStartX+200,controlStartY-(scrHeightIncrement*5),200,25],...
          'BackgroundColor',[0.6 1.0 0.6],...
          'Callback',{@initialiseModel_callback});
      
   hRunModel = uicontrol('Style','pushbutton','String','Run model',...
          'Position',[controlStartX+200,controlStartY-(scrHeightIncrement*6),200,25],...
          'BackgroundColor',[0.6 1.0 0.6],...
          'Callback',{@runModel_callback});
      
   hPlotModel = uicontrol('Style','pushbutton','String','Plot model results',...
      'Position',[controlStartX+200,controlStartY-(scrHeightIncrement*7),200,25],...
      'BackgroundColor',[0.6 1.0 0.6],...
      'Callback',{@plotModelResults_callback});
  
    % hAnalyseModelOutput = uicontrol('Style','pushbutton','String','Analyse model output',...
    %   'Position',[controlStartX+200,controlStartY-(scrHeightIncrement*8),200,25],...
    %   'BackgroundColor',[0.6 1.0 0.6],...
    %   'Callback',{@analyseModelOutput_callback});
    % 
    % hRunAndPlotAnimation = uicontrol('Style','pushbutton','String','Run and plot animation',...
    %   'Position',[controlStartX+200,controlStartY-(scrHeightIncrement*9),200,25],...
    %   'BackgroundColor',[0.6 1.0 0.6],...
    %   'Callback',{@runAndPlotAnimation_callback});
    % 
    % hPlotCrossSectionTraverseAnimation = uicontrol('Style','pushbutton','String','Plot cross-section animation',...
    %   'Position',[controlStartX+200,controlStartY-(scrHeightIncrement*10),200,25],...
    %   'BackgroundColor',[0.6 1.0 0.6],...
    %   'Callback',{@plotStrikeCrossSectionTraverseAnimation_callback});
    % 
    % hPlotStrikeVerticalSectionCorrelationTraverseAnimation_callback = uicontrol('Style','pushbutton','String','Plot correlation panel animation', ...
    %   'Position',[controlStartX+200,controlStartY-(scrHeightIncrement*11),200,25], ...
    %   'BackgroundColor',[0.6 1.0 0.6], ...
    %   'Callback',{@plotStrikeVerticalSectionCorrelationTraverseAnimation_callback});
  
    hClearResults = uicontrol('Style','pushbutton','String','Clear results',...
      'Position',[controlStartX+200,controlStartY-(scrHeightIncrement*12),200,25],...
      'BackgroundColor',[0.8 0.2 0.2],...
      'Callback',{@clearResults_callback});
    
   % Assign the GUI a name to appear in the window title.
   set(gui.main,'Name','Stacker')
   % Move the GUI to the center of the screen.
   movegui(gui.main,'center')
   % Make the GUI visible.
   set(gui.main,'Visible','on');
   
    function loadParameterFile_callback(source,eventdata)
        fprintf('\n\n===================================================== Loading Parameter Input File =====================================================\n');
        
        paramsFileNameAndPath = strcat(get(hParamsFpath,'String'),get(hParamsFname,'String'));
        
        [params, success] = loadParameterFile(params, paramsFileNameAndPath);
        if success == 1
            params.loaded = 1; % Set flag to enable rest of the button functions
        end
    end

    function initialiseModel_callback(source,eventdata)
        fprintf('\n\n===================================================== Initialising Model =====================================================\n');
             
        if params.loaded == 1
            [params, strata] = initialiseModel(params, strata);
            params.initialised = 1;
            
            fprintf('Constructing initial bathymetry plot...');
            if isfield(gui, "mainAxes")
                cla(gui.mainAxes);
            end
            
            gui.mainAxes = axes("position", [0.05, 0.05, 0.7, 0.9]);
            
            plotBathymetryAndFacies(params, strata, 1);
            fprintf('Done.\n');
        end
    end

    function runModel_callback(source,eventdata)
        fprintf('\n\n===================================================== Running Model =====================================================\n');
        
        if params.initialised == 1
            [params, strata] = runModel(params, strata, 0); % 0 indicates no animation
        end
    end

    function plotModelResults_callback(source, eventdata)
        fprintf('\n\n===================================================== Plotting Model results =====================================================\n');
        
        if params.initialised == 1 && params.modelRunCompleted == 1
            plotModelResults(params, strata);
        end
    end

    function analyseModelOutput_callback(source, eventdata)
        fprintf('\n\n===================================================== Analyse Model results =====================================================\n');
        
        if params.initialised == 1 && params.modelRunCompleted == 1
            load("typeCurves", "typeCurves"); % Loads a 4 x 100 matrix typeCurves, containing four 100-eleemnt cumulative frequency curves, for the four types of lithofacies distribution identified in Burgess (2008)
            calculateAndPlotBedThicknessDistributions(params, strata, typeCurves); % Pass type curves because cannot "add to static workspace" in function
            analyseSectionsForOrder(params, strata);
        end
    end

    function runAndPlotAnimation_callback(source,eventdata)
        fprintf('\n\n===================================================== Running Model =====================================================\n');
        
        if params.initialised == 1
            [params, strata] = runModel(params, strata, 1); % Call function with animate flag = 1
        end
    end

    function plotStrikeCrossSectionTraverseAnimation_callback(source,eventdata)
        
        fName = "animations/crossSectTraverse.gif";
        scrsz = get(0,'ScreenSize'); % screen dimensions vector
        figure('Visible','on','Position',[1 1 (scrsz(3)*0.8) (scrsz(4)*0.8)]);
        iterations = params.totalEMT / params.deltaT;
        
        for sectPosition = 1: params.gridCellsX
            clf
            drawStrikeSectionAndChronostrat(iterations, params, strata, sectPosition)
            titleStr = sprintf("x = %2.1fkm", sectPosition * params.gridDx);
            title(titleStr);
            
            frame = getframe(gcf); 
            im = frame2im(frame); 
            [imind,cm] = rgb2ind(im,256); 
            % Write to the GIF File 
            if sectPosition == 1
               imwrite(imind, cm, fName,'gif', 'Loopcount',inf, 'DelayTime',0.1); 
            else 
               imwrite(imind, cm, fName,'gif', 'WriteMode','append', 'DelayTime',0.1); 
            end   
        end
    end

    function plotStrikeVerticalSectionCorrelationTraverseAnimation_callback(source, eventdata)
        
        fName = "animations/CorrelatedverticalSectionsTraverse.gif";
        scrsz = get(0,'ScreenSize'); % screen dimensions vector
        figure('Visible','on','Position',[1 1 (scrsz(3)*0.8) (scrsz(4)*0.8)]);
        iterations = params.totalEMT / params.deltaT;
        
        thicknessMap = strata.layers(:,:,iterations) - strata.layers(:,:, 1);
        maxThickness = max(max(thicknessMap));
        
        for sectPosition = 1: params.gridCellsX
            clf
            drawVerticalSections(iterations, params, strata, maxThickness, sectPosition);
            titleStr = sprintf("x = %2.1fkm", sectPosition * params.gridDx);
            title(titleStr);
            
            frame = getframe(gcf); 
            im = frame2im(frame); 
            [imind,cm] = rgb2ind(im,256); 
            % Write to the GIF File 
            if sectPosition == 1
               imwrite(imind, cm, fName,'gif', 'Loopcount',inf, 'DelayTime',0.1); 
            else 
               imwrite(imind, cm, fName,'gif', 'WriteMode','append', 'DelayTime',0.1); 
            end   
        end
    end

    function clearResults_callback(source, eventdata)
        fprintf('\n\n===================================================== Clear All Previous Model results =====================================================\n');
        
        [params, strata run] = initialiseVariables;
    end



%% Code to read the parameter file

    function [params, success] = loadParameterFile(params, paramsFileNameAndPath)

        success = 0;
        fileIn = fopen(paramsFileNameAndPath,'r');
        if (fileIn < 0)
            fprintf('WARNING: parameter input file %s not found\n', paramsFileNameAndPath);
            success = 0;
            params.loaded = 0;    % Boolean flag to show if data loaded or not; if not, subsequent functions disabled
        else
            fprintf(' Reading parameters from filename %s\n', paramsFileNameAndPath);

            [params, initialBathymetrySuccess, sealevelCurveSuccess] = readMainModelParams(params, fileIn);
            
            if initialBathymetrySuccess && sealevelCurveSuccess

                % params.nFacies should now contain the number of facies elements so read the basic info for each
                [params, faciesElementsSuccess] = readBasicFaciesInfo(params, fileIn);

                if faciesElementsSuccess 
                    
                    % Now read what type of model the parameter file defines, so facies belts versus mosaic, and the type of production-depth relationship
                    params.modelType = fscanf(fileIn,'%s', 1);
                    fgetl(fileIn);
                    params.sedimentProductionType = fscanf(fileIn,'%s', 1); % Constant or Bosscher&Schlager curve
                    fgetl(fileIn);
                    
                    faciesElementSuccess = 0;

                    if strcmp('FaciesBelts', params.modelType)
                        
                       % For a deterministic model there should be information on the water depth range for each of the nFacies so read that
                        
                        for j = 1:params.nFacies
                            faciesCode = fscanf(fileIn,'%d', 1); % Facies code not really required but makes input file easier to read
                            fgetl(fileIn);

                            params.minWaterDepth(j) = fscanf(fileIn,'%f', 1);
                            fgetl(fileIn);
                            params.maxWaterDepth(j) = fscanf(fileIn,'%f', 1);
                            fgetl(fileIn);
                        end

                        faciesElementsSuccess = 1;
                    end
                    
                    if strcmp('FaciesMosaic', params.modelType)

                        % For a fuzzy cloud model there should be information on a number of facies clouds so read that
                        params.nFaciesMosaicElements = fscanf(fileIn,'%d', 1);
                        fgetl(fileIn);
                        params.nFaciesMosaicNumberOfCloudPoints = fscanf(fileIn,'%d', 1);
                        fgetl(fileIn);
                        params.faciesMosaicElementMovementType = fscanf(fileIn,'%s', 1);
                        fgetl(fileIn);
                        
                        [params, faciesElementsSuccess] = readFaciesFuzzyCloudDetails(params, fileIn);
                        
                        if faciesElementsSuccess == 1
                            fprintf('Read %d facies elements defined by point clouds %d\n',  params.nFaciesMosaicElements);
                        else
                            fprintf('Problems reading %d facies element point clouds - check and correct file format\n', params.nFaciesMosaicElements);
                        end
                    end    

                     if faciesElementsSuccess
                        params.loaded = 1;
                        success = 1;
                        fprintf('Read parameters file for model %s type %s to run for %d iterations for %3.2f My with %d facies on a %d by %d cell grid\n',params.modelName, params.modelType, params.totalEMT / params.deltaT, params.totalEMT, params.nFacies, params.gridCellsX, params.gridCellsY);
                     else
                        params.loaded = 0;
                        success = 0;
                     end
                end
            end
        end
    end

    function [params, initialBathymetrySuccess, sealevelCurveSuccess] = readMainModelParams(params, fileIn)
        
        params.modelName = fscanf(fileIn,'%s', 1);
        fgetl(fileIn); % Read to the end of the line to skip any label text

        % Read parameters from the main parameter file
        params.gridCellsX = fscanf(fileIn,'%d', 1);
        fgetl(fileIn);

        params.gridCellsY = fscanf(fileIn,'%d', 1);
        fgetl(fileIn);

        params.gridDx = fscanf(fileIn,'%f', 1);
        fgetl(fileIn);

        params.gridDy = fscanf(fileIn,'%f', 1);
        fgetl(fileIn);

        params.totalEMT = fscanf(fileIn,'%f', 1);
        fgetl(fileIn);

        params.deltaT = fscanf(fileIn,'%f', 1);
        fgetl(fileIn);

        params.initialBathymetryFname = fscanf(fileIn,'%s', 1);
        fgetl(fileIn);
        
        [params, initialBathymetrySuccess] = readInitialBathymetryFile(params);

        params.subsidenceRate = fscanf(fileIn,'%f', 1);
        fgetl(fileIn);

        params.sealevelCurveFname = fscanf(fileIn,'%s', 1);
        fgetl(fileIn);
        [params, sealevelCurveSuccess] = readSealevelCurveFile(params);
        
        params.intertdialWDRange = fscanf(fileIn,'%f', 1);
        fgetl(fileIn);

        params.nFacies = fscanf(fileIn,'%d', 1);
        fgetl(fileIn); 
    end

    function [params, initialBathymetrySuccess] = readInitialBathymetryFile(params)

        if exist(params.initialBathymetryFname, 'file')
            params.initialBathymetryMap = load(params.initialBathymetryFname,'-ascii');
            initialBathymetrySuccess = 1;

        else
            fprintf('WARNING: initial bathymetry file %s not found, cannot complete model initialisation\n', params.initialBathymetryFname);
            initialBathymetrySuccess = 0;    % Boolean flag to show if data loaded or not; if not, subsequent functions disabled
        end
    end

    function [params, sealevelCurveSuccess] = readSealevelCurveFile(params)

        if exist(params.sealevelCurveFname, 'file')
            params.sealevelCurve = load(params.sealevelCurveFname);
            sealevelCurveSuccess = 1;
        else
             fprintf('WARNING: sea level curve file %s not found, cannot complete model initialisation\n', params.sealevelCurveFname);
             sealevelCurveSuccess = 0;    % Boolean flag to show if data loaded or not; if not, subsequent functions disabled
        end
    end

    function [params, faciesElementsSuccess] = readBasicFaciesInfo(params, fileIn)
    % Read the basic facies information for the prescribed number of facies nFacies
       
       faciesElementsSuccess = 1;
       
       for j = 1:params.nFacies
            faciesCode = fscanf(fileIn,'%d', 1);
            fgetl(fileIn);

            if faciesCode == j

                params.deposRate(j) = fscanf(fileIn,'%f', 1);
                fgetl(fileIn);
                params.faciesRGB(j,1:3) = fscanf(fileIn,'%f', 3);
                fgetl(fileIn);
            else
                
                fprintf('File format warning - facies element %d appears to be out of sequence?\n', faciesCode);
                faciesElementsSuccess = 0;
            end
        end
    end

    function [params, faciesElementsSuccess] = readFaciesFuzzyCloudDetails(params, fileIn)
        
        for j = 1: params.nFaciesMosaicElements
            
            jCheck = fscanf(fileIn,'%d', 1); % Read the facies element number, just as a check
            fgetl(fileIn);
            if jCheck ~= j
                fprintf("Warning - facies elements mis-numbered in input file, Number %d should be number %d\n", jCheck, j);
            end

            params.faciesMosaicElementFaciesCode(j) = fscanf(fileIn,'%d', 1);
            fgetl(fileIn);
            
            params.faciesMosaicElementMigrationRateX(j) = fscanf(fileIn,'%f', 1);
            params.faciesMosaicElementMigrationRateY(j) = fscanf(fileIn,'%f', 1);
            fgetl(fileIn);
            
            params.faciesMosaicElementStartX(j) = fscanf(fileIn,'%f', 1);         
            params.faciesMosaicElementStartY(j) = fscanf(fileIn,'%f', 1);
            fgetl(fileIn);
            
            params.faciesMosaicElementRadius(j) = fscanf(fileIn,'%f', 1);
            fgetl(fileIn);
            
            cloudFilename = fscanf(fileIn,'%s', 1);
            fgetl(fileIn);
            load(cloudFilename, "cloudPointXYCoords");
            params.faciesMosaicElementpointsXY(j, :,:) = cloudPointXYCoords;
        end
        
        faciesElementsSuccess = 1; % Add error checking on fscanfs above to set to false
    end

%% Code to initialise the model

    function [params, strata] = initialiseModel(params, strata)

        rng(42); % initialise the random number generator to ensure same results each model run for any given parameters
        
        fprintf('Initialising model array...');
        
        % Calculate the total number of model iterations to run from specified duration and timestep
        run.totalIterations = params.totalEMT / params.deltaT;
        
        % Put zeros as start values in the necessary arrays
        strata.layers = zeros(params.gridCellsX, params.gridCellsY, run.totalIterations);
        strata.facies = zeros(params.gridCellsX, params.gridCellsY, run.totalIterations);    
        
        % Copy the initial bathmyetry map as the elevation of the first chron surface
        strata.layers(:,:,1) =  params.initialBathymetryMap;

        % Multiply the subsidence rate by the modle time step to ensure all rates are correct magnitude to apply per time step iteration
        params.subsidenceRate = params.subsidenceRate * params.deltaT;
        
        if strcmp('FaciesBelts', params.modelType)

            strata.facies(:,:,1) = calculateFaciesDistributionWaterDepthControl(params, strata, 1, params.sealevelCurve(1));
        end
        
        if strcmp('FaciesMosaic', params.modelType)
            
            % initalise the xy coords and alculate the x and y increments required to migrate the facies mosaic element
            j =1:params.nFaciesMosaicElements;
            strata.faciesMosaicElementX(j) = params.faciesMosaicElementStartX(j);
            strata.faciesMosaicElementY(j) = params.faciesMosaicElementStartY(j);
            strata.faciesMosaicElementXInc(j) = params.faciesMosaicElementMigrationRateX(j); 
            strata.faciesMosaicElementYInc(j) = params.faciesMosaicElementMigrationRateY(j);
            
            % Calculate the facies distribution for this initial condition
            strata = calculateFaciesDistributionMosaic(params, strata, 1, params.sealevelCurve(1));
        end
        
        strata.faciesColourMap = createFaciesColourMap(params);

        fprintf('Done.\n');
    end

    function faciesMap = calculateFaciesDistributionWaterDepthControl(params, strata, iteration, sealevel)

        waterDepth = sealevel - strata.layers(:,:,iteration);
        faciesMap = zeros(params.gridCellsY, params.gridCellsX);

        for x = 1:params.gridCellsX
            for y = 1:params.gridCellsY
                for j = 1:params.nFacies
                    if waterDepth(x,y) >= params.minWaterDepth(j) && waterDepth(x,y) < params.maxWaterDepth(j)
                        faciesMap(x,y) = j;
                    end
                end
            end
        end
    end

    function strata = calculateFaciesDistributionMosaic(params, strata, iteration, sealevel)
    % Populate the facies map for current iteration
        
        waterDepth = sealevel - strata.layers(:,:,iteration);
        strata.facies(:,:,iteration) = zeros(params.gridCellsX, params.gridCellsY); % Initialise facies map for this iteration to zeros
                
        for j = 1:params.nFaciesMosaicElements % loop to calculate for each facies mosaic element

            for k = 1:params.nFaciesMosaicNumberOfCloudPoints % loop through the points in mosaic element j
                
                x = strata.faciesMosaicElementX(j) / params.gridDx; % Convert mosaic element center point x coord from km to grid cell index
                x = x + ((params.faciesMosaicElementpointsXY(j,k,1) * params.faciesMosaicElementRadius(j)) / params.gridDx); % Add cloud point x coord to center point coord
                x = floor(x); % convert x coordinate to integer
                
                y = strata.faciesMosaicElementY(j) / params.gridDy; % Convert mosaic element center point y coord from km to grid cell index
                y = y + ((params.faciesMosaicElementpointsXY(j,k,2) * params.faciesMosaicElementRadius(j)) / params.gridDy); % Add cloud point y coord to center point coord
                y = floor(y); % convert y coordinate to integer
                
                if x > 0 && x <= params.gridCellsX && y > 0 && y <= params.gridCellsY && waterDepth(x,y) > 0.0
                    strata.facies(x,y,iteration) = params.faciesMosaicElementFaciesCode(j);
                end
            end
        end
    end

    function faciesColourMap = createFaciesColourMap(params)
        
        faciesColourMap = zeros(params.nFacies+1, 3); % +1 because need first colour for zero-value background
        faciesColourMap(1,:) = [0.99,0.99, 0.9]; % Set the background colour in element 1 to drak greenish-blue
        
        for j = 2:params.nFacies+1 % Loop through the facies, accounting for background colour in element 1
            faciesColourMap(j,:) = params.faciesRGB(j-1,:); % Set the colour map element to the appropriate facies colour input
        end
    end


%% Code to run the model

    function [params, strata] = runModel(params, strata, animateFlag)
           
        iteration = 2;
        totalIterations = params.totalEMT / params.deltaT;
        emt = 0.0;
        
        if animateFlag
           plotHandle = figure;
%            fileName = "stackerAnimated3Dplot.avi";
%            
%            vidOut = VideoWriter(fileName);
%            open(vidOut);
            fileName = "stackerAnimated3Dplot.gif";
        end
        
        while iteration <= totalIterations
            
            % Create new layer for this iteration, at same elevation as previous layer
            strata.layers(:,:,iteration) = strata.layers(:,:, iteration - 1);
            
            % Calculate subsidnece for all the layers thus far
            for subLoop = 1:iteration
                strata.layers(:,:, subLoop) = strata.layers(:,:, subLoop) - params.subsidenceRate; % * params.deltaT);
            end
            
            if strcmp('FaciesBelts', params.modelType)
                
                strata.facies(:,:,iteration) = calculateFaciesDistributionWaterDepthControl(params, strata, iteration, params.sealevelCurve(iteration));
                strata = calculateDepositionFaciesBelt(params, strata, params.sealevelCurve(iteration), iteration);
%                 strata.layers(:,:,iteration) = strata.layers(:,:,iteration-1) + calculateDepositionFaciesBelt(params, strata, params.sealevelCurve(iteration), iteration);
            end
            
            if strcmp('FaciesMosaic', params.modelType)
                
                strata = updateFaciesMosaicFuzzyLocations(params, strata, iteration, params.sealevelCurve(iteration));
                strata = calculateFaciesDistributionMosaic(params, strata, iteration, params.sealevelCurve(iteration));
                strata = calculateDepositionFuzzyMosaic(params, strata, iteration, params.sealevelCurve(iteration));
            end
            
            if animateFlag
                clf % Clear the figure to ensure clear new frame for animation
                plotBathymetryAndFacies(params, strata, iteration);
                % Create GIF version
                oneFrame = getframe(plotHandle);
                oneImage = frame2im(oneFrame);
                  [oneInd, colourMap] = rgb2ind(oneImage,256);
                  if iteration == 2
                      imwrite(oneInd,colourMap, fileName, 'gif', 'DelayTime',0.1, 'Loopcount',inf);
                  else
                      imwrite(oneInd,colourMap, fileName, 'gif', 'DelayTime',0.1, 'WriteMode','append');
                  end
%                 oneFrame = getframe(plotHandle);
%                 writeVideo(vidOut,oneFrame);
            end
            
            iteration = iteration + 1;
            emt = emt + params.deltaT;
            fprintf('It#%d Elapsed time %4.3f My\n', iteration-1, emt);
        end
        
        % Not sure how it happens, but sometimes facies code > 0 while
        % thickness = 0 and this causes problems in analysis code, so check
        % and remove occurrences now - no impact on model results??
        strata = checkAndRemoveZeroThicknessFacies(params, strata);
        
        fprintf('Model complete after %d iterations and %4.3f My\n', iteration, emt);
        
        fName = sprintf('modelResults/%s.mat', params.modelName);
        save(fName, 'params', 'strata');
        
        params.modelRunCompleted = 1;
        
        if animateFlag
%             close(vidOut);
        end
    end

    function strata = calculateDepositionFaciesBelt(params, strata, sealevel, iteration)
        % Calculate thickness of new depositional layer for iteration. Also
        % update facies record in strata is any new layer thickness is zero
        % - need to make sure no zero-thickness recorded as non-zero facies
        
        oneLayerThick = zeros(params.gridCellsY, params.gridCellsX);
        waterDepthMap = sealevel - strata.layers(:,:,iteration);
        
        for x = 1:params.gridCellsX
            for y = 1:params.gridCellsY
                
                oneFaciesCode = strata.facies(x,y,iteration-1);
                
                if oneFaciesCode > 0
                    if strcmp(params.sedimentProductionType,"Bosscher&Schlager")
                        
                        
                        % Bosscher and Sclager formula 
                        onePointProdRate = tanh((2000 * exp(-0.2 * waterDepthMap(x,y))) / 300);
                        
                        oneLayerThick(x,y) = onePointProdRate * params.deposRate(oneFaciesCode) * params.deltaT; % Bosscher and Sclager formula 
                        
                    else % If not B&S assume constant production rate with depth, at specified rate for facies
                        oneLayerThick(x,y) = params.deposRate(oneFaciesCode) * params.deltaT; % note deltaT already included in deposRate
                    end
                else
                    oneLayerThick(x,y) = 0.0;
                end
                
                % Check for deposition extending above sea-level or outside of intertidal range ...
                if strata.layers(x,y, iteration-1) + oneLayerThick(x,y) > sealevel
                    
                    newLayerThick = sealevel - strata.layers(x,y, iteration-1);
                    if newLayerThick > 0
                        oneLayerThick(x,y) = newLayerThick; % So fill the available accommodation, no more
                    else
                        oneLayerThick(x,y) = 0; % No accommodation at x,y because sealevel below elevation of previous chron surface
                        strata.facies(x,y,iteration) = 0; % Set facies to zero because thickness is zero
                    end
                end
            end
        end
        
        strata.layers(:,:,iteration) = strata.layers(:,:,iteration-1) + oneLayerThick;
    end

    function strata = updateFaciesMosaicFuzzyLocations(params, strata, iteration, sealevel)
          
        waterDepthMap = sealevel - strata.layers(:,:,iteration);
        subGridDistance = [1.414, 1.0, 1.414; 1.0, 0, 1.0; 1.414, 1.0, 1.414;];
        
        for j = 1:params.nFaciesMosaicElements
            
            if strcmp(params.faciesMosaicElementMovementType, "StraightLines")
                
                [~, strata] = checkMosaicElementGridEdge(params, strata, j);
                
                strata.faciesMosaicElementX(j) = strata.faciesMosaicElementX(j) + strata.faciesMosaicElementXInc(j);
                strata.faciesMosaicElementY(j) = strata.faciesMosaicElementY(j) + strata.faciesMosaicElementYInc(j);
            end
            
            if strcmp(params.faciesMosaicElementMovementType, "RandomWalk")
                
                [bounced, strata] = checkMosaicElementGridEdge(params, strata, j);
            
                if ~bounced && rand > 0.95 % if not reflected of grid edge and p0.05 case, randomly change direction of element migration
                    strata.faciesMosaicElementXInc(j) = params.faciesMosaicElementMigrationRateX(j) * rand;
                    strata.faciesMosaicElementXInc(j) = strata.faciesMosaicElementXInc(j) * (-1 + (2 * (rand>0.5))); % Make either positive or negative
                    strata.faciesMosaicElementYInc(j) = params.faciesMosaicElementMigrationRateY(j) * rand;
                    strata.faciesMosaicElementYInc(j) = strata.faciesMosaicElementYInc(j) * (-1 + (2 * (rand>0.5))); % Make either positive or negative
                end
            
                strata.faciesMosaicElementX(j) = strata.faciesMosaicElementX(j) + strata.faciesMosaicElementXInc(j);
                strata.faciesMosaicElementY(j) = strata.faciesMosaicElementY(j) + strata.faciesMosaicElementYInc(j);
            end
            
            if strcmp(params.faciesMosaicElementMovementType, "DeepestNeighbour")
                lowestNeighbourRadius = 20;
                % Convert decimal mosaic element center coordinates to ineger grid indices
                xco = round(strata.faciesMosaicElementX(j) / params.gridDx); 
                yco = round(strata.faciesMosaicElementY(j) / params.gridDy);
                            
                % Set the water depth sub grid limits, and manage the edge-of-grid issues
                xcoLeft = xco - lowestNeighbourRadius;
                if xcoLeft < 1 xcoLeft = 1; end
                xcoRight = xco + lowestNeighbourRadius;
                if xcoRight >  params.gridCellsX  xcoRight = params.gridCellsX; end
                ycoBottom = yco - lowestNeighbourRadius;
                if ycoBottom < 1 ycoBottom = 1; end
                ycoTop = yco + lowestNeighbourRadius;
                if ycoTop >  params.gridCellsY  ycoTop = params.gridCellsY; end
                    
                % Extract a 3x3 subgrid of difference in water depth relative to depth at xco,yco
                wdSubGrid = waterDepthMap(xcoLeft:xcoRight, ycoBottom:ycoTop);
                maxWD = min(wdSubGrid, [], "all"); % Find the maximum water depth in that subgrid
                [maxWDXpos, maxWDYpos] = find(wdSubGrid==maxWD, 1, "first"); % Get the x,y coords of the first point on the subgrid found with maxWD

                xDiff = (maxWDXpos - lowestNeighbourRadius) / lowestNeighbourRadius; % Calculate x and y increment from center point 2,2 to the deepest water depth cell
                yDiff = (lowestNeighbourRadius - maxWDYpos) / lowestNeighbourRadius;
                
                % Move mosaic element xy centroid towards the deepest water neighbour point at the specified migration rate
                strata.faciesMosaicElementX(j) = strata.faciesMosaicElementX(j) + (xDiff * params.faciesMosaicElementMigrationRateX(j));
                strata.faciesMosaicElementY(j) = strata.faciesMosaicElementY(j) + (yDiff * params.faciesMosaicElementMigrationRateY(j));
                
                if strata.faciesMosaicElementX(j) < 0 strata.faciesMosaicElementX(j) = 0; end
                if strata.faciesMosaicElementX(j) > params.gridCellsX * params.gridDx strata.faciesMosaicElementX(j) = params.gridCellsX * params.gridDx; end
                if strata.faciesMosaicElementY(j) < 0 strata.faciesMosaicElementY(j) = 0; end
                if strata.faciesMosaicElementY(j) > params.gridCellsY * params.gridDy strata.faciesMosaicElementY(j) = params.gridCellsY * params.gridDy; end
            end
            
            if strcmp(params.faciesMosaicElementMovementType, "SteepestGradient")
                
                % Convert decimal mosaic element center coordinates to ineger grid indices
                xco = round(strata.faciesMosaicElementX(j) / params.gridDx); 
                yco = round(strata.faciesMosaicElementY(j) / params.gridDy);
                            
                % Set the water depth sub grid limits, and manage the edge-of-grid issues
                xcoLeft = xco - 1;
                if xcoLeft < 1 xcoLeft = 1; end
                xcoRight = xco + 1;
                if xcoRight >  params.gridCellsX  xcoRight = params.gridCellsX; end
                ycoBottom = yco - 1;
                if ycoBottom < 1 ycoBottom = 1; end
                ycoTop = yco + 1;
                if ycoTop >  params.gridCellsY  ycoTop = params.gridCellsY; end
                    
                % Extract a 3x3 subgrid of difference in water depth relative to depth at xco,yco
                wdSubGrid = waterDepthMap(xcoLeft:xcoRight, ycoBottom:ycoTop);
                centerCellWD = wdSubGrid(2,2);
                wdSubGrid = wdSubGrid - centerCellWD; 
                wdGradSubGrid = wdSubGrid ./ subGridDistance;
                maxGrad = max(wdGradSubGrid, [], "all"); % Find the maximum water depth in that subgrid
                
                [maxWDXpos, maxWDYpos] = find(wdGradSubGrid==maxGrad, 1, "first"); % Get the x,y coords of the first point on the subgrid found with maxWD

                xDiff = maxWDXpos - 2; % Calculate x and y increment from center point 2,2 to the deepest water depth cell
                yDiff = 2 - maxWDYpos;
                
                % Move mosaic element xy centroid towards the deepest water neighbour point at the specified migration rate
                strata.faciesMosaicElementX(j) = strata.faciesMosaicElementX(j) + (xDiff * params.faciesMosaicElementMigrationRateX(j));
                strata.faciesMosaicElementY(j) = strata.faciesMosaicElementY(j) + (yDiff * params.faciesMosaicElementMigrationRateY(j));
                
                if strata.faciesMosaicElementX(j) < 1 strata.faciesMosaicElementX(j) = 1; end
                if strata.faciesMosaicElementX(j) > (params.gridCellsX - 1) * params.gridDx strata.faciesMosaicElementX(j) = (params.gridCellsX - 1) * params.gridDx; end
                if strata.faciesMosaicElementY(j) < 1 strata.faciesMosaicElementY(j) = 1; end
                if strata.faciesMosaicElementY(j) > (params.gridCellsY - 1) * params.gridDy strata.faciesMosaicElementY(j) = (params.gridCellsY - 1) * params.gridDy; end
                
            end
        end
        
        % Record the mosaic element xy positions for reference and plotting
        for j = 1:params.nFaciesMosaicElements
            strata.faciesMosaicElementTrajectoryX(j, iteration) = strata.faciesMosaicElementX(j);
            strata.faciesMosaicElementTrajectoryY(j, iteration) = strata.faciesMosaicElementY(j);
        end
    end

    function [bounced, strata] = checkMosaicElementGridEdge(params, strata, j)
       
        bounced = 0;

        % Change the direction of movement at the grid edges to bounce the polygon back on a reflecting boundary condition
        if strata.faciesMosaicElementX(j) < 0 && strata.faciesMosaicElementXInc(j) < 0.0 
            strata.faciesMosaicElementXInc(j) = abs(strata.faciesMosaicElementXInc(j));
            bounced = 1;
        end
        if strata.faciesMosaicElementX(j) > params.gridCellsX * params.gridDx && strata.faciesMosaicElementXInc(j) > 0.0 
            strata.faciesMosaicElementXInc(j) = -strata.faciesMosaicElementXInc(j); 
            bounced = 1;
        end
        if strata.faciesMosaicElementY(j) < 0 && strata.faciesMosaicElementYInc(j) < 0.0
            strata.faciesMosaicElementYInc(j) = abs(strata.faciesMosaicElementYInc(j));
            bounced = 1;
        end
        if strata.faciesMosaicElementY(j) > params.gridCellsY * params.gridDy && strata.faciesMosaicElementYInc(j) > 0.0
            strata.faciesMosaicElementYInc(j) = -strata.faciesMosaicElementYInc(j);
            bounced = 1;
        end 
    end

    function strata = calculateDepositionFuzzyMosaic(params, strata, iteration, sealevel)
        
        producersPerCell = calculateProducersPerGridCell(params, strata, iteration);
        waterDepthMap = sealevel - strata.layers(:,:,iteration);
        
        for x = 1:params.gridCellsX
            for y = 1:params.gridCellsY
                
                faciesAtXY = strata.facies(x,y,iteration);
                if faciesAtXY > 0
                    
                    if strcmp(params.sedimentProductionType,"Bosscher&Schlager")
                        
                        % Bosscher and Sclager formula Surface light intensity 2000, Extinction coefficient 0.2, Saturating light 300
                        % glob.prodDepthAdjust(y,x) =  tanh((glob.surfaceLight(oneFacies) * exp(-glob.extinctionCoeff(oneFacies) * waterDepth)) / glob.saturatingLight(oneFacies));
                        onePointProdRate = tanh((2000 * exp(-0.2 * waterDepthMap(x,y))) / 300);
                        
                        onePointDeposThick = onePointProdRate * params.deposRate(faciesAtXY) * producersPerCell(x,y,faciesAtXY) * params.deltaT; % NB subsidence rate is already rate per My
                        strata.layers(x,y,iteration) = strata.layers(x,y,iteration-1) + onePointDeposThick;
                        
                    else % If not B&S assume constant production rate with depth, at specified rate for facies
                       
                        onePointDeposThick = params.deposRate(faciesAtXY) * producersPerCell(x,y,faciesAtXY) * params.deltaT; % NB subsidence rate is already rate per My
                        strata.layers(x,y,iteration) = strata.layers(x,y,iteration-1) + onePointDeposThick;
                    end
                    
                    % Check for deposition extending above sea-level ...
                    if strata.layers(x,y, iteration) > sealevel
                        strata.layers(x,y, iteration) = sealevel;
                    end
                end
            end
        end
    end

    function producersPerCell = calculateProducersPerGridCell(params, strata, iteration)
    % Calculate a normalised count of producing elements per model grid cell for current iteration
    % Deposition rate calculated per facies (not per mosaic element!), so nFacies layers in the map
    
        producersPerCell = zeros(params.gridCellsX, params.gridCellsY, params.nFacies);
        
        for j = 1:params.nFaciesMosaicElements
            for k = 1:params.nFaciesMosaicNumberOfCloudPoints
                
                x = strata.faciesMosaicElementX(j) / params.gridDx; % Convert from km to grid cell index
                x = x + ((params.faciesMosaicElementpointsXY(j,k,1) * params.faciesMosaicElementRadius(j)) / params.gridDx);
                x = floor(x);
                
                y = strata.faciesMosaicElementY(j) / params.gridDy; % Convert from km to grid cell index
                y = y + ((params.faciesMosaicElementpointsXY(j,k,2) * params.faciesMosaicElementRadius(j)) / params.gridDy);
                y = floor(y);
                
                if x > 0 && x <= params.gridCellsX && y > 0 && y <= params.gridCellsY
                    producersPerCell(x,y,params.faciesMosaicElementFaciesCode(j)) = producersPerCell(x,y,params.faciesMosaicElementFaciesCode(j)) + 1;
                end
            end
        end
        
        for j = 1:params.nFacies
            maxCount = max(max(producersPerCell(:,:,j))); % Find the maximum count in layer j, so max for facies j
            producersPerCell(:,:,j) = producersPerCell(:,:,j) ./ maxCount; % normalise the facies count for layer j
        end
    end

    function strata = checkAndRemoveZeroThicknessFacies(params, strata)
        
        totalIterations = size(strata.facies,3);
        
         for x = 1:params.gridCellsX % loop through all grid points and iterations
            for y = 1:params.gridCellsY
                for t= 2:totalIterations
                    % if the grid point has a recorded facies but zero or
                    % negative thickness, remove the recorded facies code
                    if strata.facies(x,y,t) > 0 && strata.layers(x,y,t) - strata.layers(x,y,t-1) <= 0
                        strata.facies(x,y,t) = 0;
                    end
                end
            end
         end
    end
%% Plotting routines

    function plotModelResults(params, strata)
        
        fName = sprintf('modelResults/%s.mat', params.modelName);
        load(fName, 'params', 'strata');
        
        iteration = params.totalEMT / params.deltaT;
        
        fprintf('Drawing 3D bathymetry and strat...');
        figure % Draw final bathyemtry and facies in a separate figure, not in the main GUI window
        plotBathymetryAndFacies(params, strata, iteration-1);
        fprintf('Done\n');
        
        fprintf('Drawing dip section & chronostrat...');
        sectXPosition = round( params.gridCellsX / 2);
        drawDipSectionAndChronostrat(iteration-1, params, strata, sectXPosition); 
        fprintf('Done\n');
        
        fprintf('Drawing vertical sections...');
        figure; % Need to create new figure because not in drawVerticalSection function so it can be called for animatio
        sectYPosition = round( params.gridCellsX / 2);
        drawVerticalSections(iteration, params, strata, 0, sectYPosition); % 0 is dummy max thickness value - only needed when calling function to make animation
        fprintf('Done\n');

        fprintf('Drawing facies polygon trajectories...');
        if strcmp('FaciesMosaic', params.modelType)
            drawPolygonTrajectories(iteration-1, params, strata);
        end 
        fprintf('Done\n');
        
%         Code to plot initial facies mosaic condition with polygon trajectors for 100 iterations of run model
%         clf
%         plotBathymetryAndFacies(params, strata, 1);
%         drawPolygonTrajectories(100, params, strata)

    end

    function plotBathymetryAndFacies(params, strata, layerNumber)
                
        xcoVect = 0:params.gridDx:params.gridDx * (params.gridCellsX-1); % Define the x and y coordinate vectors for the model grid
        ycoVect = 0:params.gridDy:params.gridDy * (params.gridCellsY-1);
        [xcoGrid,ycoGrid] = meshgrid(xcoVect, ycoVect); % Create the whole grid xy coordinates
        elevationsToPlot = strata.layers(:,:,layerNumber).'; % Note because of how surf works, xy axes need to be transposed to plot correctly - annoying but necessary!
        coloursToPlot = createColourTripletMap(strata.faciesColourMap, strata.facies(:,:,layerNumber).');
%        disp(size(strata.layers));
%        disp(size(strata.facies));
%         faciesToPlot = strata.facies(:,:,layerNumber).';
%         surfLeesh = surf(xcoGrid, ycoGrid, elevationsToPlot, faciesToPlot); % Plot the initial condition bathymetry colour coded by facies
        surfLeesh = surf(xcoGrid, ycoGrid, elevationsToPlot, coloursToPlot); % the initial condition bathymetry colour coded by facies
        set(surfLeesh, 'EdgeColor',[0.8, 0.8, 0.9])
        colormap(strata.faciesColourMap)
        
        hold on
        
        draw3DCrossSectionDip(layerNumber, params, strata, 1, 1); % Final 1 is 3d flag set to true
        draw3DCrossSectionDip(layerNumber, params, strata, params.gridCellsY-1, 1); % -1 because surf grid scaled from 0 not 1 Final 1 is 3d flag set to true
        draw3DCrossSectionStrike(layerNumber, params, strata, params.gridCellsX-1, 1); % -1 because surf grid scaled from 0 not 1
        draw3DCrossSectionStrike(layerNumber, params, strata, 1, 1); % Final 1 is 3d flag set to true
        
        % Define the coordinates for the sea-level surface
        xco = [0, 0, params.gridCellsX * params.gridDx, params.gridCellsX * params.gridDx];
        yco = [0, params.gridCellsY * params.gridDy, params.gridCellsY * params.gridDy, 0];
        zco = [params.sealevelCurve(layerNumber), params.sealevelCurve(layerNumber), params.sealevelCurve(layerNumber), params.sealevelCurve(layerNumber)];
        patch(xco, yco, zco, [0 0.2 1.0], 'FaceAlpha',0.5); % Draw sea-level surface

        if strcmp('FaciesMosaic', params.modelType) && layerNumber > 1 % only draw trajectories for mosaic option when model has run for at least one time step
	         drawPolygonTrajectories(layerNumber - 1, params, strata);
        end
        
        grid on;
        ylabel('Dip distance (y) (km)');
        xlabel('Strike distance (x) (km)');
        zlabel('Elevation (z) (m)');
        titleStr = sprintf("Elapsed time %5.4f My", layerNumber * params.deltaT);
        title(titleStr);
        view(220,40); 
        drawnow
    end

    function coloursToPlot = createColourTripletMap(colourMap, faciesMap)
        
        [xSize, ySize] = size(faciesMap);
        coloursToPlot = zeros(xSize, ySize, 3);
              
        % Create RGB colour triplet for each point on the model grid according to the facies code at each point
        for x=1:xSize
            for y = 1:ySize
                % Note the y,x order to populate the coloursToPlot matrix - not sure why this is required to plot correctly, but it is - something to do with the surf command??
                coloursToPlot(x,y,:) = colourMap(faciesMap(x,y) + 1,:); % +1 because facies zero (hiatus) maps to row 1 in the colour map matrix
            end
        end
        disp(size(coloursToPlot));
    end

    function drawDipSectionAndChronostrat(iterations, params, strata, sectXPosition)
        
%         scrsz = get(0,'ScreenSize'); % screen dimensions vector
%         ffSects = figure('Visible','on','Position',[1 1 (scrsz(3)*0.8) (scrsz(4)*0.8)]);
%         
%         sectXPosition = 50;
        
        subplot(2,1,1);
        
        % Draw the chronostratigraphic diagram
        for timeLoop = 1:iterations-1
            for y = 1:params.gridCellsY
                
                yco = [(y * params.gridDy) - (params.gridDy * 0.5), (y * params.gridDy) + (params.gridDy * 0.5), (y * params.gridDy) + (params.gridDy * 0.5), (y * params.gridDy) - (params.gridDy * 0.5)];
                zco = [timeLoop * params.deltaT, timeLoop * params.deltaT, (timeLoop+1) * params.deltaT, (timeLoop+1) * params.deltaT];
                onePointFacies = strata.facies(sectXPosition, y, timeLoop);
                if onePointFacies > 0
                    colour = [params.faciesRGB(onePointFacies, 1), params.faciesRGB(onePointFacies, 2), params.faciesRGB(onePointFacies, 3)];
                    patch(yco, zco, colour, 'LineStyle','none');
                end
            end
        end
        
        grid on;
        axis tight
        xlabel('Dip distance (x) (km)');
        ylabel('Geological time (My)');
        
        subplot(2,1,2);
        
        draw3DCrossSectionDip(iterations, params, strata, sectXPosition, 0); % 0 value for 3D flag, so indicate draw in 2D
        grid on;
        axis tight;
        xlabel('Dip distance (y) (km)');
        ylabel('Elevation (z) (m)');
    end

function drawStrikeSectionAndChronostrat(iterations, params, strata, sectYPosition)
        
        subplot(2,1,1);
        
        % Draw the chronostratigraphic diagram
        for timeLoop = 1:iterations-1
            for x = 1:params.gridCellsY
                
                xco = [(x * params.gridDy) - (params.gridDy * 0.5), (x * params.gridDy) + (params.gridDy * 0.5), (x * params.gridDy) + (params.gridDy * 0.5), (x * params.gridDy) - (params.gridDy * 0.5)];
                zco = [timeLoop * params.deltaT, timeLoop * params.deltaT, (timeLoop+1) * params.deltaT, (timeLoop+1) * params.deltaT];
                onePointFacies = strata.facies(x, sectYPosition, timeLoop);
                if onePointFacies > 0
                    colour = [params.faciesRGB(onePointFacies, 1), params.faciesRGB(onePointFacies, 2), params.faciesRGB(onePointFacies, 3)];
                    patch(xco, zco, colour, 'LineStyle','none');
                end
            end
        end
        
        grid on;
        axis tight
        xlabel('Strike distance (x) (km)');
        ylabel('Geological time (My)');
        
        subplot(2,1,2);
        
        draw3DCrossSectionStrike(iterations, params, strata, sectYPosition, 0); % 0 value for 3D flag, so indicate draw in 2D
        grid on;
        ylim([-30, 0]);
        xlabel('Strike distance (y) (km)');
        ylabel('Elevation (z) (m)');
    end

   function draw3DCrossSectionDip(iterations, params, strata, sectPosition, flag3D)
        
        maxPts = params.gridCellsY; % No deposition polygon can be bigger than the whole grid *2, but *2 required for yco top and base
        gridCellSize = params.gridDx;
        
        for timeLoop = 2:iterations
            
            coordLoop = 1; % Start at the proximal end of the grid
            while coordLoop < maxPts
                    
                deposThickFlag = 0; % Flag used indicate if any depositional thickness has been found during a loop iteration
                yco = nan(1, maxPts); % polygon coordinate arrays, won't need to be params.gridCellY big, but pre-allocate makes this much faster
                zcoBase = nan(1, maxPts);
                zcoTop = nan(1, maxPts);   
                
                start = coordLoop; % Remember y as the starting point for the while loop below
                if start > 1
                    pointCount = 2; % Start from 2 because we will need to add a taper to zero thickness at point 1
                else
                    pointCount = 1; % Polygon edge at egde of grid so no need to add taper, so no need lead space at y=1
                end
                
                % Found a non-zero facies code but different from y+1 code, so single point deposition
                if strata.facies(sectPosition, coordLoop, timeLoop) > 0 && strata.facies(sectPosition, coordLoop, timeLoop) ~=  strata.facies(sectPosition, coordLoop+1, timeLoop)
                    
                    if start > 1 && start <= params.gridCellsY % So not on the left margin of the grid
                        yco(pointCount-1:pointCount+1) = ((coordLoop - 1): (coordLoop + 1)) * gridCellSize;
                        zcoBase(pointCount-1:pointCount+1) = strata.layers(sectPosition, coordLoop-1:coordLoop+1, timeLoop-1);
                        zcoTop(pointCount-1:pointCount+1) =  strata.layers(sectPosition, coordLoop-1:coordLoop+1, timeLoop);
                    elseif start == 1 % Special two point case for the y=1 point on the grid
                        yco(pointCount:pointCount+1) = (coordLoop: (coordLoop + 1)) * gridCellSize;
                        zcoBase(pointCount:pointCount+1) = strata.layers(sectPosition, coordLoop:coordLoop+1, timeLoop-1);
                        zcoTop(pointCount:pointCount+1) =  strata.layers(sectPosition, coordLoop:coordLoop+1, timeLoop);
                    else % Special two point case for the y=params.gridCellsY point on the grid
                        yco(pointCount-1:pointCount) = ((coordLoop - 1): coordLoop) * gridCellSize;
                        zcoBase(pointCount-1:pointCount) = strata.layers(sectPosition, coordLoop-1:coordLoop, timeLoop-1);
                        zcoTop(pointCount-1:pointCount) =  strata.layers(sectPosition, coordLoop-1:coordLoop, timeLoop);
                    end
                    
                    coordLoop = coordLoop + 1;
                    deposThickFlag = 1; % Flag that deposition has been found
                else
                    % loop while on the grid and same deposition as previous point in the loop
                    while coordLoop < maxPts && strata.facies(sectPosition, coordLoop, timeLoop) ==  strata.facies(sectPosition, coordLoop+1, timeLoop) 

                        % Record the relevant y, facies patch top and base coordinates at y
                        yco(pointCount) =  coordLoop * gridCellSize;
                        zcoBase(pointCount) = strata.layers(sectPosition, coordLoop, timeLoop-1);
                        zcoTop(pointCount) =  strata.layers(sectPosition, coordLoop, timeLoop);

                        pointCount = pointCount + 1;
                        coordLoop = coordLoop + 1;
                        deposThickFlag = 1; % Flag that deposition has been found
                    end
                   
                    if deposThickFlag > 0 % Check if deposition has been found in the loop - need to add taper if it has...
                   
                        if start > 1 % Add a taper to zero thickness on the left edge of the polygon if end of polygon is not at the edge of the grid
                            yco(1) = (start - 1) * gridCellSize;
                            zcoBase(1) = strata.layers(sectPosition, start-1, timeLoop-1);
                            zcoTop(1) = zcoBase(1);
                        end

                        if coordLoop < maxPts % - 1 % Add a taper to zero thickness on the right edge of the polygon if end of polygon is not at the edge of the grid
                            yco(pointCount) = coordLoop * gridCellSize;
                            zcoBase(pointCount) = strata.layers(sectPosition, coordLoop, timeLoop-1);
                            zcoTop(pointCount) = zcoBase(pointCount);
                        end
                    end
                end

                if deposThickFlag > 0 % Check if deposition has been found either for one point or multiple - plot if it has ...
                    
                    yco = yco(~isnan(yco)); % Remove all nan values
                    yco = [yco flip(yco)]; % Duplicate the coordinate vector, with the second half in reverse order
                    zcoBase = zcoBase(~isnan(zcoBase)); % Remove all nan values
                    zcoTop = zcoTop(~isnan(zcoTop)); % Remove all nan values
                    zcoAll = [zcoBase flip(zcoTop)]; % merge the base coordinates and inverted order top coordinates to make one closed polygon zcoordinate vector
                    xco = ones(1, numel(yco)) * sectPosition * gridCellSize; % create the yco vector, all same coordinate in the plane of the section

                    onePointFacies = strata.facies(sectPosition, start, timeLoop); % Get the colour for the facies from the start point
                    if onePointFacies > 0 && numel(yco) > 0
                        colour = [params.faciesRGB(onePointFacies, 1), params.faciesRGB(onePointFacies, 2), params.faciesRGB(onePointFacies, 3)];
                        
                        if flag3D
                            patch(xco, yco, zcoAll, colour, 'LineStyle','none');
                        else
                            patch(yco, zcoAll, colour, 'LineStyle','none');
                        end
                    end
                else
                    coordLoop = coordLoop + 1; % no deposition found, so move on to next y point to check
                end
            end
        end
   end

    function draw3DCrossSectionStrike(iterations, params, strata, sectPosition, flag3D)
        
        maxPts = params.gridCellsX; % No deposition polygon can be bigger than the whole grid *2, but *2 required for yco top and base
        gridCellSize = params.gridDx;
        
        for timeLoop = 2:iterations
            
            coordLoop = 1; % Start at the proximal end of the grid
            while coordLoop < maxPts
                    
                deposThickFlag = 0; % Flag used indicate if any depositional thickness has been found during a loop iteration
                xco = nan(1, maxPts); % polygon coordinate arrays, won't need to be params.gridCellY big, but pre-allocate makes this much faster
                zcoBase = nan(1, maxPts);
                zcoTop = nan(1, maxPts);   
                
                start = coordLoop; % Remember y as the starting point for the while loop below
                if start > 1
                    pointCount = 2; % Start from 2 because we will need to add a taper to zero thickness at point 1
                else
                    pointCount = 1; % Polygon edge at egde of grid so no need to add taper, so no need lead space at y=1
                end
                
                % Found a non-zero facies code but different from y+1 code, so single point deposition
                if strata.facies(coordLoop, sectPosition, timeLoop) > 0 && strata.facies(coordLoop, sectPosition, timeLoop) ~=  strata.facies(coordLoop+1, sectPosition, timeLoop)
                    
                    if start > 1 && start <= params.gridCellsY % So not on the left margin of the grid
                        xco(pointCount-1:pointCount+1) = ((coordLoop - 1): (coordLoop + 1)) * gridCellSize;
                        zcoBase(pointCount-1:pointCount+1) = strata.layers(coordLoop-1:coordLoop+1, sectPosition, timeLoop-1);
                        zcoTop(pointCount-1:pointCount+1) =  strata.layers(coordLoop-1:coordLoop+1, sectPosition, timeLoop);
                    elseif start == 1 % Special two point case for the y=1 point on the grid
                        xco(pointCount:pointCount+1) = (coordLoop: (coordLoop + 1)) * gridCellSize;
                        zcoBase(pointCount:pointCount+1) = strata.layers(coordLoop:coordLoop+1, sectPosition, timeLoop-1);
                        zcoTop(pointCount:pointCount+1) =  strata.layers(coordLoop:coordLoop+1, sectPosition, timeLoop);
                    else % Special two point case for the y=params.gridCellsY point on the grid
                        xco(pointCount-1:pointCount) = ((coordLoop - 1): coordLoop) * gridCellSize;
                        zcoBase(pointCount-1:pointCount) = strata.layers(coordLoop-1:coordLoop, sectPosition, timeLoop-1);
                        zcoTop(pointCount-1:pointCount) =  strata.layers(coordLoop-1:coordLoop, sectPosition, timeLoop);
                    end
                    
                    coordLoop = coordLoop + 1;
                    deposThickFlag = 1; % Flag that deposition has been found
                else
                    % loop while on the grid and same deposition as previous point in the loop
                    while coordLoop < maxPts && strata.facies(coordLoop, sectPosition, timeLoop) ==  strata.facies(coordLoop+1, sectPosition, timeLoop) 

                        % Record the relevant y, facies patch top and base coordinates at y
                        xco(pointCount) =  coordLoop * gridCellSize;
                        zcoBase(pointCount) = strata.layers(coordLoop, sectPosition, timeLoop-1);
                        zcoTop(pointCount) =  strata.layers(coordLoop, sectPosition, timeLoop);

                        pointCount = pointCount + 1;
                        coordLoop = coordLoop + 1;
                        deposThickFlag = 1; % Flag that deposition has been found
                    end
                   
                    if deposThickFlag > 0 % Check if deposition has been found in the loop - need to add taper if it has...
                   
                        if start > 1 % Add a taper to zero thickness on the left edge of the polygon if end of polygon is not at the edge of the grid
                            xco(1) = (start - 1) * gridCellSize;
                            zcoBase(1) = strata.layers(start-1, sectPosition, timeLoop-1);
                            zcoTop(1) = zcoBase(1);
                        end

                        if coordLoop < maxPts % - 1 % Add a taper to zero thickness on the right edge of the polygon if end of polygon is not at the edge of the grid
                            xco(pointCount) = coordLoop * gridCellSize;
                            zcoBase(pointCount) = strata.layers(coordLoop, sectPosition, timeLoop-1);
                            zcoTop(pointCount) = zcoBase(pointCount);
                        end
                    end
                end

                if deposThickFlag > 0 % Check if deposition has been found either for one point or multiple - plot if it has ...
                    
                    xco = xco(~isnan(xco)); % Remove all nan values
                    xco = [xco flip(xco)]; % Duplicate the coordinate vector, with the second half in reverse order
                    zcoBase = zcoBase(~isnan(zcoBase)); % Remove all nan values
                    zcoTop = zcoTop(~isnan(zcoTop)); % Remove all nan values
                    zcoAll = [zcoBase flip(zcoTop)]; % merge the base coordinates and inverted order top coordinates to make one closed polygon zcoordinate vector
                    yco = ones(1, numel(xco)) * sectPosition * gridCellSize; % create the yco vector, all same coordinate in the plane of the section

                    onePointFacies = strata.facies(start, sectPosition, timeLoop); % Get the colour for the facies from the start point
                    if onePointFacies > 0 && numel(xco) > 0
                        colour = [params.faciesRGB(onePointFacies, 1), params.faciesRGB(onePointFacies, 2), params.faciesRGB(onePointFacies, 3)];
                        
                        if flag3D
                            patch(xco, yco, zcoAll, colour, 'LineStyle','none');
                        else
                            patch(xco, zcoAll, colour, 'LineStyle','none');
                        end
                    end
                else
                    coordLoop = coordLoop + 1; % no deposition found, so move on to next y point to check
                end
            end
        end
        
%         drawnow
    end

    function drawVerticalSections(iterations, params, strata, maxThick, vertSectPositionsY)
        
        figure;
        
        vertSectPositionsX = [1, 25, 50, 75, 99];
        % vertSectPositionsY = [1, 25, 50, 75, 99]; % for code version with more complex non-orthognal section positions
        verticalSectionsN = numel(vertSectPositionsX); % section count used multiple times so set variable for speed
        vertSectLayers = zeros(numel(vertSectPositionsX), iterations);
        distanceAlongSection = zeros(1, numel(vertSectPositionsX));
        numberOfTimeLines = 10;
        timeLineInterval = fix(iterations / numberOfTimeLines);
        
        for j = 1:verticalSectionsN % loop to draw each vertical section
            
            % Extract vertical section data from the specified point and plot that one vertical section on the panel 
            oneSectLayers = strata.layers(vertSectPositionsX(j), vertSectPositionsY, 1:iterations);
            oneSectFacies = strata.facies(vertSectPositionsX(j), vertSectPositionsY, 1:iterations); % Extract the thicknesses and facies codes from strata layers
            oneSectLayers = reshape(oneSectLayers,[1,iterations]);
            oneSectFacies = reshape(oneSectFacies,[1,iterations]); % reshape into simple 1D vectors
            oneSectLayers = oneSectLayers - oneSectLayers(1); % remove any difference in start elevation at the base of the section
            vertSectLayers(j,:) = oneSectLayers; % Copy section layer elevation values into array used to plot correlation time lines

%             xOffset = vertSectPositionsX(1) - vertSectPositionsX(1);
%             yOffset = vertSectPositionsY - vertSectPositionsY;
%             distanceAlongSection(j) = sqrt((xOffset * xOffset) + (yOffset * yOffset));
%             plotOneVerticalSection(params, oneSectLayers, oneSectFacies, distanceAlongSection(j));

            plotOneVerticalSection(params, oneSectLayers, oneSectFacies, vertSectPositionsX(j));
        end
          
        for j = 1:verticalSectionsN % loop aagin to draw time correlation lines
            for t=1:timeLineInterval:iterations
                if j < verticalSectionsN % Draw time line through section and then draw connecting line to the next section on the right
%                     xco = [distanceAlongSection(j), distanceAlongSection(j) + params.nFacies, distanceAlongSection(j+1)];
                    xco = [vertSectPositionsX(j), vertSectPositionsX(j) + params.nFacies, vertSectPositionsX(j+1)];
                    yco = [vertSectLayers(j,t), vertSectLayers(j,t), vertSectLayers(j+1,t)];
                else % Time line only two points for the right-most section
%                     xco = [distanceAlongSection(j), distanceAlongSection(j) + params.nFacies];
                    xco = [vertSectPositionsX(j), vertSectPositionsX(j) + params.nFacies];
                    yco = [vertSectLayers(j,t), vertSectLayers(j,t)];
                end
                line(xco, yco, 'color','b');
            end
        end
        
        xlim([0, vertSectPositionsX(verticalSectionsN) + params.nFacies]);
        if maxThick > 0
            ylim([0, maxThick]); % Only set y max mlimit to maxThick when maxThick paramter passed to function > 0
        end
        
        grid on;
%         titleStr = sprintf("Dip position %d", vertSectPositionsY);
%         title(titleStr);
        xlabel('Distance along section (km)');
        ylabel('Thickness (m)');
    end

    function plotOneVerticalSection(params, vertSectLayers, vertSectFacies, xScreen)
    % Assume sections passed with base elevation = 0
        
        totalLayers = numel(vertSectLayers);
        
        % Calculate x coordinate, distance along the correlation panel section, according to xy position
        
        for timeLoop = 2:totalLayers
            
            if vertSectFacies(timeLoop) > 0 % Can only plot deposition, so check for non-deposition facies code zero
                yco = [xScreen, xScreen + vertSectFacies(timeLoop), xScreen + vertSectFacies(timeLoop), xScreen];
                zco = [vertSectLayers(timeLoop-1), vertSectLayers(timeLoop-1), vertSectLayers(timeLoop), vertSectLayers(timeLoop)];
                
                if vertSectFacies(timeLoop) > 0
                    colour = params.faciesRGB(vertSectFacies(timeLoop), 1:3);
                    patch(yco, zco, colour, 'LineStyle','none');
                end
            end
        end
    end


    function drawPolygonTrajectories(iteration, params, strata)
        
        figure;
        
        for j = 1:params.nFaciesMosaicElements
        
            xco = strata.faciesMosaicElementTrajectoryX(j, 2:iteration);
            yco = strata.faciesMosaicElementTrajectoryY(j, 2:iteration);
            zco = zeros(1, iteration-1);
            faciesCode = params.faciesMosaicElementFaciesCode(j);
            line(xco, yco, zco, "color", params.faciesRGB(faciesCode,1:3), "marker", "o" );
        end
        
        grid on;
        xlabel("Strike distance (x) (km)");
        ylabel("Dip distance (y) (km)");
    end

    function calculateAndPlotBedThicknessDistributions(params, strata, typeCurves)
        
        [allSectsThickDistrib, allSectsThicknessBins, numberOfBedsMap, totalThicknessMap] = getAllModelBedThicknessDistributions(params, strata);
                    
        calculateAndPlotExponentialCurveMatches(params, allSectsThickDistrib, allSectsThicknessBins, numberOfBedsMap, totalThicknessMap);
        
        calculateAndPlotOutcropCurveMatches(params, typeCurves, allSectsThickDistrib, allSectsThicknessBins);
    end

    

    function [allSectsThickDistrib, allSectsThicknessBins, numberOfBedsMap, totalThicknessMap] = getAllModelBedThicknessDistributions(params, strata)

        oneSectThicknessBins = zeros(1,100);
        allSectsThickDistrib = zeros(params.gridCellsX, params.gridCellsY, numel(oneSectThicknessBins));
        totalIterations = params.totalEMT / params.deltaT;
        numberOfBedsMap = zeros(params.gridCellsX, params.gridCellsY);
        totalThicknessMap = zeros(params.gridCellsX, params.gridCellsY);

        % loop through all the vertical sections across the model grid and define a bed thickness distribution at each point where there are
        % enough beds and thick enough strata
        for x = 1:params.gridCellsX 
            for y = 1:params.gridCellsY

                t = 2:totalIterations;
                oneSectThickness = reshape(strata.layers(x,y,t) - strata.layers(x,y,t-1),[1,totalIterations-1]); % extract section thickness and facies values at x,y
                oneSectFacies = reshape(strata.facies(x,y,2:totalIterations),[1,totalIterations-1]);

                if sum(oneSectFacies > 0) > 20 && sum(oneSectThickness) > 1.0 % more than 20 beds and total thickness > 1.0m in this vertical section

                    % Calculate the store the bed thickness distribution details at x,y
                    [oneSectThickDistrib, oneSectThicknessBins, numberOfBedsMap(x,y), totalThicknessMap(x,y)]  = calculateOneSectThickDistrib(oneSectThickness, oneSectFacies);
                    allSectsThickDistrib(x,y,:) = oneSectThickDistrib;
                    allSectsThicknessBins(x,y,:) = oneSectThicknessBins;
                end
            end
        end
    end

function [oneSectThickCumRelFrequencies, oneSectThicknessBins, numberOfBeds, totalThickness] = calculateOneSectThickDistrib(oneSectThickness, oneSectFacies)
 
        oneSectThicknessMerged = zeros(1,numel(oneSectThickness));
        oneSectFaciesMerged = zeros(1,numel(oneSectThickness));
        
        % First need to merge all same-facies sets of iterations to calculate bed thickness for the section
        k = 1;
        oneSectThicknessMerged(1) = oneSectThickness(1);
        oneSectFaciesMerged(1) = oneSectFacies(1);
        for j =2:numel(oneSectFacies)
            if oneSectFacies(j) == oneSectFacies(j-1) && oneSectFacies(j) > 0 % Facies at two consecutive iterations are the same and unit j not zero ...
                oneSectThicknessMerged(k) = oneSectThicknessMerged(k) + oneSectThickness(j); % Next bed is same facies, so add thickness of next bed j to new bed k
            elseif oneSectFacies(j) > 0
                k = k + 1; % Bed j is different facies to j-1 so increment k to move to the next bed
                oneSectThicknessMerged(k) = oneSectThickness(j);
                oneSectFaciesMerged(k) = oneSectFacies(j);
            end
        end
        
        % Keep only facies and thickness where layer value for time step is >0
        oneSectFaciesMerged = oneSectFaciesMerged(oneSectFaciesMerged > 0); 
        oneSectThicknessMerged = oneSectThicknessMerged(oneSectThicknessMerged > 0);
        
        maxSectThickness = max(oneSectThicknessMerged);
        oneSectThicknessBins = 0.0:(maxSectThickness / 99):maxSectThickness;
        numberOfBeds = numel(oneSectFaciesMerged);
        totalThickness = sum(oneSectThicknessMerged);
        
        % Calculate the frequency of occurrence of bed thicknesses in the vertical section
        oneSectThickFrequencies = histcounts(oneSectThicknessMerged, oneSectThicknessBins);
        oneSectThickCumFrequencies = zeros(1, numel(oneSectThickFrequencies));
        oneSectThickCumFrequencies(1) = oneSectThickFrequencies(1);
        for j= 2:numel(oneSectThickFrequencies) % Loop to calculate cumulative frequency
            oneSectThickCumFrequencies(j) = oneSectThickCumFrequencies(j-1) + oneSectThickFrequencies(j);
        end
        oneSectThickCumRelFrequencies = oneSectThickCumFrequencies / max(oneSectThickCumFrequencies); % Convert to relative frequency
        oneSectThickCumRelFrequencies = [0, oneSectThickCumRelFrequencies]; % make sure series starts with zero value - important for plotting etc
    end

    function calculateAndPlotExponentialCurveMatches(params, allSectsThickDistrib, allSectsThicknessBins, numberOfBedsMap, totalThicknessMap)
        
        
%         pValueMap = zeros(params.gridCellsX, params.gridCellsY);
        expErrorMapExponential = nan(params.gridCellsX, params.gridCellsY);
        expErrorMapColourCoded = zeros(params.gridCellsX, params.gridCellsY); % store a colour code 1=green, 2 =yellow, 3 = red for the error map plotting, calculated according to defined ebst-fit error threshdolds
        expErrorBestFit = 200.0; % min and max starting values used to find minimum and maximum error
        expErrorWorstFit = 0.0;
        
        for x = 1:params.gridCellsX
            for y = 1:params.gridCellsY
                
                
                oneSectThicknessDistrib = reshape(allSectsThickDistrib(x,y, :), [1,100]);
                oneSectThicknessBins = reshape(allSectsThicknessBins(x,y,:),[1,100]);
                
                % Calculate an exponential distribution with the same total thickness and number of beds and
                % calculate difference with stacker model distriubition from point xy
                exponentialCDF = 1 - exp(-((numberOfBedsMap(x,y) / totalThicknessMap(x,y)) * oneSectThicknessBins));
                expErrorMapExponential(x,y) = sum(abs(oneSectThicknessDistrib - exponentialCDF)) / sum(exponentialCDF);

                % Could shortern/simplify code by just store all thickness bins, sections and exponential sections then choose with pvalue map to decide whcih to plot

                if expErrorMapExponential(x,y) > expErrorWorstFit % so pValueMap(x,y)
                    worstFitThicknessBins = oneSectThicknessBins; % need to reshape from 3D array extraction to 1d vector
                    worstFitOneSectThickDistrib = oneSectThicknessDistrib; % Assumes discrete CDF has 100 elements
                    worstFitExponentialCDF = exponentialCDF;
                    worstFitXco = x;
                    worstFitYco = y;
                    expErrorWorstFit = expErrorMapExponential(x,y);
                end

                if expErrorMapExponential(x,y) < expErrorBestFit
                    bestFitThicknessBins = oneSectThicknessBins;
                    bestFitOneSectThickDistrib = oneSectThicknessDistrib;
                    bestFitExponentialCDF = exponentialCDF;
                    bestFitXco = x;
                    bestFitYco = y;
                    expErrorBestFit = expErrorMapExponential(x,y);
                end

                % Colour code green bar for <5% error, yellow for <10%, red for >=10%
                if expErrorMapExponential(x,y) < 0.05
                    expErrorMapColourCoded(x,y) = 0.5;
                elseif expErrorMapExponential(x,y) < 0.10
                    expErrorMapColourCoded(x,y) = 1.5;
                else
                    expErrorMapColourCoded(x,y) = 2.5;
                end
            end
        end
       
        lowestErrorSectionCount = sum(sum(expErrorMapExponential < 0.05));
        indeterminateSectionCount = sum(sum(expErrorMapExponential < 0.075)) - lowestErrorSectionCount;
        highestErrorSectionCount = sum(sum(expErrorMapExponential >= 0.075));
        
        fprintf("Good match with exponential %d (%4.3f)\nIndeterminate %d (%4.3f)\nNon-exponential %d (%4.3f)\n", ...
            lowestErrorSectionCount, lowestErrorSectionCount / (params.gridCellsX * params.gridCellsY),  ...
            indeterminateSectionCount, indeterminateSectionCount / (params.gridCellsX * params.gridCellsY), ...
            highestErrorSectionCount, highestErrorSectionCount / (params.gridCellsX * params.gridCellsY));
          
        % plot the best and worse thickness distribution matches with expoential curves
        figure
        subplot(2,1, 1);
        plot(worstFitThicknessBins, worstFitOneSectThickDistrib,"LineWidth", 3, "color", [0,0.2,1]);
        hold on;
        plot(worstFitThicknessBins, worstFitExponentialCDF, "LineWidth", 3, "color", [0.9, 0.8, 0.8], "LineStyle", "-.");
        xlabel("Lithofacies thickness (m)");
        ylabel("Cumulative relative frequency");
        grid on;
        titleStr = sprintf("Worst fit curve error=%5.4f x=%d y=%d %d beds, total thickness %3.2f m", expErrorMapExponential(worstFitXco, worstFitYco), worstFitXco, worstFitYco, numberOfBedsMap(worstFitXco, worstFitYco), totalThicknessMap(worstFitXco, worstFitYco));
        title(titleStr);
        
        subplot(2,1, 2);
        plot(bestFitThicknessBins, bestFitOneSectThickDistrib,"LineWidth", 3, "color", [0,0.2,1]);
        hold on;
        plot(bestFitThicknessBins, bestFitExponentialCDF, "LineWidth", 3, "color", [0.9, 0.8, 0.8], "LineStyle", "-.");
        xlabel("Lithofacies thickness (m)");
        ylabel("Cumulative relative frequency");
        grid on;
        titleStr = sprintf("Best fit curve error=%5.4f x=%d y=%d %d beds, total thickness %3.2f m", expErrorMapExponential(bestFitXco, bestFitYco), bestFitXco, bestFitYco, numberOfBedsMap(bestFitXco, bestFitYco), totalThicknessMap(bestFitXco, bestFitYco));
        title(titleStr);
        
        figure
        imagesc(expErrorMapColourCoded);
        % Create error map colour map
        errorColourMap = [0,1,0; 1,1,0; 1,0,0;];
        colormap(errorColourMap);
        xlabel("Strike distance (km)");
        ylabel("Dip distance (km)");
        title("Error map");
        grid on
        colorbar;
    end

function calculateAndPlotOutcropCurveMatches(params, typeCurves, allSectsThickDistrib, allSectsThicknessBins)
    
        errorMap = nan(4, params.gridCellsX, params.gridCellsY);
        errorMapColourCoded = nan(4, params.gridCellsX, params.gridCellsY);
        goodMatchCount = zeros(1,4);
        intermediateMatchCount = zeros(1,4);
        poorMatchCount = zeros(1,4);
        
        % plot all the model bed thickness disibutions compared to the four outcrop-type distributions from Burgess (2008)
        figure
        hold on
        for x = 1:params.gridCellsX
            for y = 1:params.gridCellsY
                onePlotThickness = allSectsThicknessBins(x,y,:);
                onePlotCumFreq = allSectsThickDistrib(x,y,:);
                onePlotThickness = reshape(onePlotThickness,[1,numel(onePlotThickness)]);
                onePlotCumFreq = reshape(onePlotCumFreq,[1,numel(onePlotThickness)]);
                
                for j = 1:4
                    % Calculate error between modelled curve and each outcrop curve from Burgess (2008)
                    oneTypeCurve = reshape(typeCurves(:,j+1),[1,101]);
                    oneTypeCurve = oneTypeCurve(2:101);
                    errorMap(j,x,y) = sum(abs(onePlotCumFreq - oneTypeCurve)) / sum(oneTypeCurve);
               
                    % Colour code green bar for <5% error, yellow for <10%, red for >=10%
                    if errorMap(j,x,y) < 0.05
                        errorMapColourCoded(j, x,y) = 0.5;
                        goodMatchCount(j) = goodMatchCount(j) + 1;
                    elseif errorMap(j, x,y) < 0.10
                        errorMapColourCoded(j, x,y) = 1.5;
                        intermediateMatchCount(j) = intermediateMatchCount(j) + 1;
                    else
                        errorMapColourCoded(j, x,y) = 2.5;
                        poorMatchCount(j) = poorMatchCount(j) + 1;
                    end
                end
                
                % plot modelled thickness distribution from point xy
                plot(onePlotThickness, onePlotCumFreq, "LineWidth", 0.1, "color",[0.2,0.2,0.2]);
            end
        end
        
        
        for j = 1:4
            fprintf("Good match with type %d outcrop curve %d (%4.3f)\nIntermediate match with type %d outcrop curve %d (%4.3f)\nPoor match with type %d outcrop curve %d (%4.3f)\n", ...
                j, goodMatchCount(j), goodMatchCount(j) / (params.gridCellsX * params.gridCellsY),  ...
                j, intermediateMatchCount(j), intermediateMatchCount(j) / (params.gridCellsX * params.gridCellsY),  ...
                j, poorMatchCount(j), poorMatchCount(j) / (params.gridCellsX * params.gridCellsY));
        end
        
        if poorMatchCount == params.gridCellsX * params.gridCellsY
            errorMapColourCoded(:, 1,1) = 0.5; % Fix one point at low error to ensure colour map works preoperly
        end
        
        maxThickness = max(max(max(allSectsThicknessBins)));
        typeCurves(:,1) = typeCurves(:,1) .* maxThickness;
        for j =2:4
            plot(typeCurves(:,1), typeCurves(:,j), "LineWidth",3.0);
        end
        
        xlabel("Lithofacies thickness (m)");
        ylabel("Cumulative relative frequency");
        grid on;
        
        % Draw ma
        figure
        errorColourMap = [0,1,0; 1,1,0; 1,0,0;]; % Same colour bar for each subplot figure so create here
        
        for j = 1:4
            subplot(2,2,j);
            oneErrorMapColourCoded = errorMapColourCoded(j,:,:); % Extract map as a 1 x gridSize x gridSize matrix
            oneErrorMapColourCoded = reshape(oneErrorMapColourCoded, [max(size(oneErrorMapColourCoded)), max(size(oneErrorMapColourCoded))]); % reshape to be a gridSize x gridSize matrix as required by imagesc
            imagesc(oneErrorMapColourCoded);
            colormap(errorColourMap);

%             oneErrorMap = errorMap(j,:,:); % Extract map as a 1 x gridSize x gridSize matrix
%             oneErrorMap = reshape(oneErrorMap, [max(size(oneErrorMap)), max(size(oneErrorMap))]); % reshape to be a gridSize x gridSize matrix as required by imagesc
%             imagesc(oneErrorMap);


            xlabel("Strike distance (km)");
            ylabel("Dip distance (km)");
            titleStr = sprintf("Outcrop type curve %d", j);
            title(titleStr);
            grid on
%             colorbar;
        end
    end

    function analyseSectionsForOrder(params, strata)
        
        totalIterations = params.totalEMT / params.deltaT;
        totalSectionsAnalysed = 0;
        pValueMarkovMap = nan(params.gridCellsX, params.gridCellsY);
        pValueRunsMap = nan(params.gridCellsX, params.gridCellsY);
        pValueMarkovMapColourCoded = nan(params.gridCellsX, params.gridCellsY);
        pValueRunsMapColourCoded = nan(params.gridCellsX, params.gridCellsY);
        
        fprintf("Analysing all vertical sections for runs and facies transition order...\nX ");
        
        for x = 1:params.gridCellsX
            for y = 1:params.gridCellsY
                
                t = 2:totalIterations;
                vertSectThick = reshape(strata.layers(x,y,t) - strata.layers(x,y,t-1),[1,totalIterations-1]);
                vertSectFacies = reshape(strata.facies(x,y,2:totalIterations),[1,totalIterations-1]);
                [vertSectThickContinuous, vertSectFaciesContinuous] = calculateContinousVerticalSection(vertSectThick, vertSectFacies);
                
                numberOfFacies = numel(unique(vertSectFaciesContinuous));
                if numberOfFacies > 3 && numel(vertSectFaciesContinuous) >= 20
                
                    [pValueMarkovMap(x,y), pValueRunsMap(x,y)] = calculateMarkovAndRunsPValues(vertSectFaciesContinuous, vertSectThickContinuous);
                    totalSectionsAnalysed = totalSectionsAnalysed + 1;
                    
                    if pValueMarkovMap(x,y) < 0.05
                        pValueMarkovMapColourCoded(x,y) = 0.5;
                    elseif pValueMarkovMap(x,y) < 0.075
                        pValueMarkovMapColourCoded(x,y) = 1.5;
                    else
                        pValueMarkovMapColourCoded(x,y) = 2.5;
                    end
                    
                    if pValueRunsMap(x,y) < 0.05
                        pValueRunsMapColourCoded(x,y) = 0.5;
                    elseif pValueRunsMap(x,y) < 0.075
                        pValueRunsMapColourCoded(x,y) = 1.5;
                    else
                        pValueRunsMapColourCoded(x,y) = 2.5;
                    end
                end    
            end
            
            fprintf(".");
        end
        
        fprintf("Complete\n");
        markovOrderedCount = sum(sum(pValueMarkovMap <= 0.01));
        markovIntdeterminateCount = sum(sum(pValueMarkovMap <= 0.1)) - markovOrderedCount;
        markovDisorderedCount = sum(sum(pValueMarkovMap > 0.1));
        runsOrderedCount = sum(sum(pValueRunsMap <= 0.01));
        runsIntdeterminateCount = sum(sum(pValueRunsMap <= 0.1)) - runsOrderedCount;
        runsDisorderedCount = sum(sum(pValueRunsMap > 0.1));
        fprintf("Sections with ordered facies %d (%4.3f) indeterminate %d (%4.3f) and disordered %d (%4.3f)\n", ...
            markovOrderedCount, markovOrderedCount / totalSectionsAnalysed, ...
            markovIntdeterminateCount, markovIntdeterminateCount / totalSectionsAnalysed,...
            markovDisorderedCount, markovDisorderedCount / totalSectionsAnalysed);
        fprintf("Sections with ordered thickness %d (%4.3f) indeterminate %d (%4.3f) and disordered %d (%4.3f)\n", ...
            runsOrderedCount, runsOrderedCount / totalSectionsAnalysed, ...
            runsIntdeterminateCount, runsIntdeterminateCount / totalSectionsAnalysed, ...
            runsDisorderedCount, runsDisorderedCount / totalSectionsAnalysed);
        
        
        
        figure
        
        % Create error map colour map
        pValueColourMap = [0,1,0; 1,1,0; 1,0,0;];
        colormap(pValueColourMap);
        
        subplot(2,1, 1);
        imagesc(pValueMarkovMapColourCoded);
        xlabel("Strike distance (km)");
        ylabel("Dip distance (km)");
        title("Markov analysis facies order p values");
        grid on
        colorbar;
        
        subplot(2,1, 2);
        imagesc(pValueRunsMapColourCoded);
        xlabel("Strike distance (km)");
        ylabel("Dip distance (km)");
        title("Runs analysis thickness trends p values");
        grid on
        colorbar;
    end

    function [vertSectThickContinuous, vertSectFaciesContinuous] = calculateContinousVerticalSection(vertSectThick, vertSectFacies)
        
        vertSectThick = vertSectThick(vertSectThick > 0); % Zero values not needed here so remove from both facies and thickness section
        vertSectFacies = vertSectFacies(vertSectFacies > 0);
        vertSectThickContinuous = zeros(1,numel(vertSectThick));
        vertSectFaciesContinuous = zeros(1,numel(vertSectThick));
        
        % First need to merge all same-facies sets of iterations to calculate bed thickness for the section
        k = 1;
        vertSectThickContinuous(1) = vertSectThick(2); % 2 because layer 2 in strata arrays is the first calculated iteration after the initial condition in layer 1
        vertSectFaciesContinuous(1) = vertSectFacies(2);
        for j =3:numel(vertSectFacies)
            if vertSectFacies(j) == vertSectFacies(j-1) % Facies at two consecutive iterations are the same and unit j not zero ...
                vertSectThickContinuous(k) = vertSectThickContinuous(k) + vertSectThick(j); % Next bed is same facies, so add thickness of next bed j to new bed k
            else
                k = k + 1; % Bed j is different facies to j-1 so increment k to move to the next bed
                vertSectThickContinuous(k) = vertSectThick(j);
                vertSectFaciesContinuous(k) = vertSectFacies(j);
            end
        end
        
        vertSectThickContinuous = vertSectThickContinuous(vertSectThickContinuous > 0);
        vertSectFaciesContinuous = vertSectFaciesContinuous(vertSectFaciesContinuous > 0);
        if numel(vertSectFaciesContinuous) ~= numel(vertSectThickContinuous)
            fprintf("Warning - continuous facies section %d units not the same length as %d thickness units\n", ...
                numel(vertSectFaciesContinuous), numel(vertSectThickContinuous));
        end
    end

    function [pValueMarkov, pValueRuns] = calculateMarkovAndRunsPValues(vertSectFacies, vertSectThick)

        maxIterations = 100;
        numberOfSwaps = numel(vertSectFacies);
        maxRun = 3;
        minRun = 0;
        runBinIncrement = 0.05;
        runRange = maxRun - minRun;

        % Calculate and output the order metric for this one vertical succession
        markovOrderMetric = calculateTPMatrixAndOrderMetric(vertSectFacies);  
        runsOrderMetric = calculateRunsOrderMetric(vertSectThick);
        
        % Now calculate the metrics for many iterations of a random model
        multiMarkovOrderMetricDataShuffled = zeros(1, maxIterations);
        multiRunsOrderMetricDataShuffled = zeros(1, maxIterations);
        
        % Shuffle the observed section and calculate the facies and thickness order metrics each time
        for j = 1:maxIterations  
            [shuffledFacies, shuffledThick] = shuffleSectionNoSameTransitions(vertSectFacies, vertSectThick, numberOfSwaps);
            multiMarkovOrderMetricDataShuffled(j) = calculateTPMatrixAndOrderMetric(shuffledFacies); 
            multiRunsOrderMetricDataShuffled(j) = calculateRunsOrderMetric(shuffledThick);     
        end

        bins = 0.0:0.02:1.00; % because 0<m<=1
        multiMarkovOrderMetricDataShuffledHistData = histcounts(multiMarkovOrderMetricDataShuffled, bins) / maxIterations; % Calculate frequency bins with histc but / by iterations to give relative freq
        pValueMarkov = sum(multiMarkovOrderMetricDataShuffledHistData(round(markovOrderMetric * 50) : length(bins)-1)); % area under curve from m to max m value 1
            
        % Stats on the shuffled section random model - thickness
        bins = 0:0.05:runRange; % 0 is the minimum run metric, 3 a generally maximum value (this is what runRange should be set to)
        multiRunsOrderMetricDataShuffledHistData = histc(multiRunsOrderMetricDataShuffled, bins)/maxIterations; % Calculate frequency bins with histc but / by iterations to give relative freq
        runBinIndex = 1 + int16(((runsOrderMetric-minRun)/runRange)*(runRange/runBinIncrement)); % Position of runs stat in the histogram
        pValueRuns = sum(multiRunsOrderMetricDataShuffledHistData(runBinIndex:length(multiRunsOrderMetricDataShuffledHistData))); % area under curve from r to max run value
    end

    function [shuffledFacies, shuffledThick] = shuffleSectionNoSameTransitions(sectFacies, sectThick, totalSwaps)
    % function to shuffle the facies and thickness succession to ensure a random configuration, and assuring no adjacent same facies occurrences in final section
    % NB only works if more than three distinct facies in the section because not possible to avoid adjacent facies occurrences with fewer

        % Make copies of the original data in new arrays that will be used to
        % store the shuffled sections
        shuffledFacies = sectFacies;
        shuffledThick = sectThick;
        n = uint16(max(size(shuffledFacies)));
        completedSwaps = 0;
        noSwapCount = 0;

        while completedSwaps < totalSwaps && noSwapCount < 100

            % Select two unit numbers randomly to be swapped
            unit1 = uint16((rand * (n-1)) + 1);
            unit2 = uint16((rand * (n-1)) + 1);

            % Need to check above and below for both positions that swapping will not put same
            % facies adjacent to one another and cause a transition to self
            swapFacies1 = shuffledFacies(unit1);
            if unit1 > 1 swapFacies1Below = shuffledFacies(unit1-1); else swapFacies1Below = 0;end
            if unit1 < n swapFacies1Above = shuffledFacies(unit1+1); else swapFacies1Above = 0;end

            swapFacies2 = shuffledFacies(unit2);
            if unit2 > 1 swapFacies2Below = shuffledFacies(unit2-1); else swapFacies2Below = 0;end
            if unit2 < n swapFacies2Above = shuffledFacies(unit2+1); else swapFacies2Above = 0;end

            % So compare facies in their new positions with the facies above and below and
            % only swap and increment loop counter if NOT the same...
            if swapFacies1Below ~= swapFacies2 && swapFacies1Above ~= swapFacies2 && swapFacies2Below ~= swapFacies1 && swapFacies2Above ~= swapFacies1

                %Swap the facies
                temp = shuffledFacies(unit1);
                shuffledFacies(unit1) = shuffledFacies(unit2);
                shuffledFacies(unit2) = temp;

                %Swap the thicknesses
                temp = shuffledThick(unit1);
                shuffledThick(unit1) = shuffledThick(unit2);
                shuffledThick(unit2) = temp;

                completedSwaps = completedSwaps + 1;
            else
                noSwapCount = noSwapCount + 1;
            end
        end
        
        if noSwapCount == 100
            fprintf("Warning - lithofacies unit swapping exited with %d swaps and %d no swaps recorded\n", completedSwaps, noSwapCount);
        end
    end
    
    function markovOrderMetric = calculateTPMatrixAndOrderMetric(vertSectFacies)

        % Find the maximum facies code used in the facies succession - this is the size for both dimensions of the TP matrix which can now be defined
        nFacies = max(vertSectFacies); 
        TFMatrix = zeros(nFacies, nFacies);
        TPMatrix = zeros(nFacies, nFacies);
     
        % Now loop through the elements in the succession and for each different facies from-to transition, increment the appropriate cell in the matrix
        for j = 1 : numel(vertSectFacies)-1
            fromFacies = vertSectFacies(j); % Get from and to from the strat column constructed above
            toFacies = vertSectFacies(j+1);
            % mark transitions between different facies
            if fromFacies > 0 && toFacies > 0 && fromFacies ~= toFacies % Make sure facies codes are not zero because zero values would record an error
                TFMatrix(fromFacies, toFacies) = TFMatrix(fromFacies, toFacies) + 1; % increment the appropriate value in the tp matrix
            end
        end

        %Now calculate the transition probability matrix from the transition frequency matrix
        rowSums=sum(TFMatrix,2); % Calculates the sum of each row in TF matrix and stores as vector rowSums
        for k=1:nFacies
            for j=1:nFacies
                if rowSums(k) > 0 % if rowsum > 0 divide TF value by row sum to get transition probability
                    TPMatrix(k,j)=TFMatrix(k,j) / rowSums(k);
                else
                    TPMatrix(k,j) = 0;
                end
            end
        end

        rowMaxs = max(TPMatrix,[],2);
        rowMins = min(TPMatrix,[],2);
        rowDiffs = rowMaxs - rowMins;
        markovOrderMetric = mean(rowDiffs);
    end

    function runsOrderMetric = calculateRunsOrderMetric(sectThicknesses)

        % find the number of units in the succession and declare arrays accordingly
        nz = max(size(sectThicknesses));
        deltaThick = zeros(1,nz);
        runsUp = zeros(1,nz);
        runsDown = zeros(1,nz);

        % Calculate the change in thickness between successive units
        i = 1:nz-1;
        j =2:nz; % so j = i + 1 therefore thickness change is thickness(j) - thickness(i)
        deltaThick(i) = sectThicknesses(j) - sectThicknesses(i);

        if deltaThick(1) > 0 runsUp(1) = 1; end
        if deltaThick(1) < 0 runsDown(1) = 1; end

        for i=2:nz
            if deltaThick(i) > 0 runsUp(i) = runsUp(i-1)+1; end
            if deltaThick(i) < 0 runsDown(i) = runsDown(i-1)+1; end
        end

        runsUpNormSum = (sum(runsUp)/nz);
        runsDownNormSum = (sum(runsDown)/nz);
        runsOrderMetric = (runsUpNormSum + runsDownNormSum);
    end

    
end