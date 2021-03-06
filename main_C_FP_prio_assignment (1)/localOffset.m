% 
% cptasks - A MATLAB(R) implementation of schedulability tests for
% conditional and parallel tasks
%
% Copyright (C) 2014-2015  
% ReTiS Lab - Scuola Superiore Sant'Anna - Pisa (Italy)
%
% cptasks is free software; you can redistribute it
% and/or modify it under the terms of the GNU General Public License
% version 2 as published by the Free Software Foundation, 
% (with a special exception described below).
%
% Linking this code statically or dynamically with other modules is
% making a combined work based on this code.  Thus, the terms and
% conditions of the GNU General Public License cover the whole
% combination.
%
% cptasks is distributed in the hope that it will be
% useful, but WITHOUT ANY WARRANTY; without even the implied warranty
% of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License version 2 for more details.
%
% You should have received a copy of the GNU General Public License
% version 2 along with cptasks; if not, write to the
% Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
% Boston, MA 02110-1301 USA.
%
%
% Author: 2015 Alessandra Melani
%

function lo = localOffset(task, i)
% ind: index of the task
% i: index of the vertex within the task of which we want to compute
% the local offset
% returns the local offset of a vertex in a conditional DAG task (used for the test by Baruah)
    
    if isempty(task.v(i).pred)
        lo = 0;
    else
        lo = 0;
        for j = 1 : length(task.v(i).pred)
            tlo = localOffset(task, task.v(i).pred(j)) + task.v(task.v(i).pred(j)).C; % tentative local offset
            if tlo > lo
                lo = tlo;
            end    
        end
    end
end