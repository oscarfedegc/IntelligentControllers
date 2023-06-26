% Class for generating reference trajectories
classdef ITrajectory < handle
    properties (Access = protected)
        instants, positions, period {mustBeNumeric}
        samples {mustBeInteger}
        units % {mustBe Meters, Radians, etc}
        type % {mustBeString}
    end
    
    methods (Access = public)
        %{
        %   Class constructor
        %       
        %   @param {float} tFinal Total time in seconds for the simulation.
        %   @param {float} period Sampling time in seconds of the system for which the trajectory is generated.
        %   @returns {object} self Instantiation of the class.
        %}
        function self = ITrajectory(tFinal, period, units)
            self.samples = round(tFinal/period);
            self.instants = linspace(0, tFinal, self.samples)';
            self.positions = [];
            self.period = period;
            self.units = units;
        end
        
        %{
        %   This function add a trajectory
        %
        %   @param {object} self Instation of the class.
        %   @param {array<float>} references Reference positions for all trajectory.
        %}
        function add(self, references)
            % Request the reference positions if missing params
            if nargin < 1                
                points = ITrajectory.getNumeric('Indique cuántas referencias usará', true, true);
                
                references = zeros(points,1);
                
                for idx = 1:points
                    references(idx) = ITrajectory.getNumeric('Indique la posición [grados]', false, false);
                end
            end
           
            self.newTrajectory(references);
        end
        
        function addPositions(self, references, times)
            self.newPosition(references, times);
        end
        
        function staticReferences(self)
            T = self.period;
    
            ta = 0:T:2.5;
            ya = 28*sin(pi.*ta/1.5);

            tb = 2.5 + T: T: 5;
            yb = 15 * ones(1,length(tb));

            tc = 5 + T: T: 7.5;
            yc = -15 * ones(1,length(tc));

            td = 7.5 + T: T: 10;
            yd = 12*sin(pi.*td./2) + 4*sin(pi.*td./3) + 8*sin(pi.*td);

            TT = [ta tb tc td]';
            if strcmp(self.units, 'rads')
                YY = deg2rad([ya yb yc yd]');
            else
                YY = [ya yb yc yd]';
            end

            te = 0: T: 5;
            ye = 12*sin(pi.*te./5);

            tf = 5 + T: T: 10;
            yf = 10*sin(pi.*tf./5) + 2*sin(pi.*tf/0.5);

            TU = [te tf]';
            
            if strcmp(self.units, 'rads')
                YU = deg2rad([ye yf]');
            else
                YU = [ye yf]';
            end
            
            self.positions = [YY YU];
        end
    end
    
    % Getters and setter of the class
    methods (Access = public)
        function samples = getSamples(self)
            samples = self.samples;
        end
        
        function instant = getTime(self, iter)
            instant = self.instants(iter);
        end
        
        function rst = getInstants(self)
            rst = self.instants;
        end

        function references = getAllReferences(self)
            references = self.positions;
        end
        
        function positions = getReferences(self, iter)
            positions = self.positions(iter,:);
        end
        
        function position = getPosition(self, iter, degree)
            position = self.positions(iter, degree);
        end
        
        function trajectory = getTrajectory(self, degree)
            trajectory = self.positions(:, degree);
        end
        
        function setReferences(self, references)
            self.positions = references;
        end
        
        function setTypeRef(self, type)
            self.type = type;
        end
        
        function type = getTypeRef(self)
            type = self.type;
        end
    end
    
    methods (Access = protected)
        %{
        %   This function converts the reference point in polynomial trajectories
        %
        %   @param {object} self Instation of the class.
        %   @param {array<float>} references Reference positions for all trajectory.
        %}
        function newTrajectory(self, references)
            if strcmp(self.units,'rads')
                references = deg2rad(references);
            end
            temp = zeros(self.samples, 1);
            
            % Calculating intervals for the equation's cases
            intervals = round(linspace(1, self.samples, length(references)));
            
            % Calculating the angles positions about the axis
            for idx = 1:length(intervals)-1
                start = intervals(idx);
                finish = intervals(idx+1);
                
                t = self.instants(start:finish);
                
                temp(start:finish) = self.segment(t, references(idx), references(idx+1));
            end
            
            self.positions = [self.positions temp];
        end
        
        %{
        %   This function converts the reference point in polynomial trajectories
        %
        %   @param {object} self Instation of the class.
        %   @param {array<float>} references Reference positions for all trajectory.
        %}
        function newPosition(self, references, times)
            if strcmp(self.units,'rads')
                references = deg2rad(references);
            end
            temp = zeros(self.samples, 1);
            times = [0 times] ./ self.period;
            
            % Calculating intervals for the equation's cases
            intervals = length(times);
            
            % Calculating the angles positions about the axis
            for idx = 1:intervals - 1
                start = times(idx) + 1;
                finish = times(idx + 1);
                
                t = self.instants(start:finish);
                
                temp(start:finish) = references(idx);
            end
            
            self.positions = [self.positions temp];
        end
        
        %{
        %   This function calculates the values of the polynomial reference
        %
        %   @param {array<float>} time Interval of time in seconds for the segment.
        %   @param {float} init_pos Initial position for the segment in radians.
        %   @param {float} final_pos Final positions of the segment in radians.
        %}
        function rst = segment(~, time, init_pos, final_pos)
            t = (time-min(time))/(max(time)-min(time));
            rst = init_pos + 3*(final_pos-init_pos)*t.^2 - 2*(final_pos-init_pos)*t.^3;
        end
        
        %{
        %   This function request a numeric value
        %
        %   @param {string} msg Message that will be displayed in console.
        %   @param {boolean} isInteger Determines if an integer is request or not.
        %   @param {boolean} isPositive Determines if a positive number is request or not.
        %   @returns {float} info The valie given by the user.
        %}
        function info = getNumeric(~, msg, isInteger, isPositive)
            while true
                try
                    info = input(sprintf('%50s: ', msg));
                    
                    if isInteger
                        info = round(info);
                    end
                    
                    if isPositive
                        info = abs(info);
                    end
                    break
                catch
                    continue
                end
            end
        end
    end
end