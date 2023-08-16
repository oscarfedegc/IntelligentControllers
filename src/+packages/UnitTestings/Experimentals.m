function Experimentals
    references = struct('pitch',  [0 10 10 0 0 -10 -10 0]', ...
                        'yaw',    [0 -10 -10 0 0 10 10 0]', ...
                        'tpitch', [0 5 15 20 35 40 55 60]',...
                        'tyaw',   [0 10 15 25 35 45 55 60]');
                         
    trajectories = ITrajectory(60, 0.005, 'rads');
    trajectories.setTypeRef('T01')
    trajectories.addPositionsWithTime(references)
    
    instants = trajectories.getInstants();
    positions = trajectories.getAllReferences();
    size(positions)
    
    plot(instants, positions(:,1))
    hold on
    plot(instants, positions(:,2))
end