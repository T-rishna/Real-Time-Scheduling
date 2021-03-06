
function updated_DAG = set_artificial_constraints(v)
global task;
global m;
global task_num;
global intermediate_dag;
global root;
global leaf;
global reduc_stg2_flag;
global forbidden_pair;
global children_with_cycles;


if isempty (forbidden_pair)
    forbidden_pair = [0 0];
end
siblings_parent=[];
i=1;    
constr_num=0;
y=0;
j=0;
% nodes = numel(fieldnames(task(i).v));
nodes = length(v);
s_factor= {0,0.25,0.5,0,75,1}; 
arti_constr_pair =[];

%com_succ= [];
%%%%%%%%%%%%%%%%%%%ensure the succ and pred elements aren't repeated
for p0= 1:nodes
    v(p0).succ= unique(v(p0).succ);
    v(p0).pred= unique(v(p0).pred);

end

%%%%%%%%%%%%%%%%%%%%%%%%%collect pairs with com child and parent%%%%%%
for x0= 1:nodes   %must be nodes-1 -TODO
	k=x0+1;
	
    
    for y =k:nodes % implement break when k=nodes-TODO
            com_succ = intersect(v(x0).succ, v(y).succ);
		if (~isempty(com_succ))
			comm_pred = intersect(v(x0).pred,v(y).pred);
			if (~isempty(comm_pred))
                
                pair= [x0 y];
                pair_in_forbidden = ismember(forbidden_pair, pair,'rows')
                if(all(pair_in_forbidden(:))==false) %check if this pair is in the forbidden pair group
				constr_num= constr_num+1;
                arti_constr_pair(constr_num, 1) = x0;
                arti_constr_pair(constr_num, 2) = y;
				
                end
		
            end
        end  
    end
end



%%%%%%%%%%%%%%%%TO ADD CONSTRAINTS & REMOVE ADDITIONAL PATHS %%%%%%%%%%
if(constr_num>0) 
   
     for x1= 1:constr_num
         %%%%new change%%%%%%
         temp=v;
         [bond_formed_1,temp_checked_1] = is_bondformed_func(temp,arti_constr_pair(x1,:));
         if(bond_formed_1)
             intermediate_dag(x1).v1 = temp_checked_1; 
             [intermediate_dag(x1).path_num,intermediate_dag(x1).path_weight]=  paths_weights(intermediate_dag(x1).v1);
             intermediate_dag(x1).load_diff_inter = max(intermediate_dag(x1).path_weight)-min(intermediate_dag(x1).path_weight);
             intermediate_dag(x1).paths_n = length(intermediate_dag(x1).path_num);
%              printTask(intermediate_dag(x1).v1);
         else
               arti_constr_pair(x1,:)=fliplr(arti_constr_pair(x1,:)) %check if the flipped siblings cause cycles
              [bond_formed_2,temp_checked_2] = is_bondformed_func(temp,arti_constr_pair(x1,:));
              if(bond_formed_2)
                 intermediate_dag(x1).v1 = temp_checked_2; 
                 [intermediate_dag(x1).path_num,intermediate_dag(x1).path_weight]=  paths_weights(intermediate_dag(x1).v1);
                 intermediate_dag(x1).load_diff_inter = max(intermediate_dag(x1).path_weight)-min(intermediate_dag(x1).path_weight);
                 intermediate_dag(x1).paths_n = length(intermediate_dag(x1).path_num);
%                  printTask(intermediate_dag(x1).v1);
             else
                 intermediate_dag(x1).v1 = v; %revert to original
              end
         end
     end
      selection_func(0)



    
    
     %%%%%%%%%%%%%%%%%%%%%% NO common parent-child DAGSs%%%%%%%%%%%%%%%%%%%%
else
    if (constr_num==0)
      
        %%%%%%%%%%%%%%%%%%%%%%%%%collect siblings%%%%%%%%%%%%%%%%%%%%%%%%%%
        j=0;
        for y0= 1:nodes
            if( (length(v(y0).succ)>1) && (v(y0).forbidden~=1))
            j=j+1;
            siblings_parent(j,1)= y0;  %colect parents with 2 more children
            siblings_parent(j,2)=v(y0).depth;
            end
        end
        
            if(isempty(siblings_parent)) %no parent exists
                children_with_cycles=1;
                intermediate_dag(1).v1 = v;
                [intermediate_dag(1).path_num,intermediate_dag(1).path_weight]=  paths_weights(intermediate_dag(1).v1);
                intermediate_dag(1).load_diff_inter = max(intermediate_dag(1).path_weight)-min(intermediate_dag(1).path_weight);
                intermediate_dag(1).paths_n = length(intermediate_dag(1).path_num);
                decision_func();
            else
        %%%%%%%%%%%%%%%% sort children based on weight   %%%%%%%%%%%%%%%
            [~,parents_index]= min(siblings_parent(:,2)); % find the parent with the lowest depth
            z= siblings_parent(parents_index,1);
            siblings= v(z).succ;
            intermediate_dag(1).v1 = v;
            
            for m0= 1:length(siblings)
                siblings_withweights(m0,1)= siblings(m0); %1ST Column is the sibling 
                siblings_withweights(m0,2)= intermediate_dag(1).v1(siblings(m0)).C % 2 nd column contains their corresponding weight
            end
            
            
            %%%%%% connection always from z0 to z1, z0 is either the lowest
            %%%%%% weight or the parent sibling 
            
            sorted_siblings= sortrows(siblings_withweights,2) ;%sort children based on their weight(exec time),const btw mimn and next min weight nodes, connect z0 to z1
            z0= sorted_siblings(1); %lowest weight node
            z1= sorted_siblings(2);  %2nd lowest node
                  
            if (ismember(z0,intermediate_dag(1).v1(z1).succ)) %if z0 is a child of z1
            z0= sorted_siblings(2); %source
            z1= sorted_siblings(1); %destination
            end
            
           
        %%%%%%%%%%%%%%%% if leaf is one of the child connections set to preserve the leaf's property- no succ   %%%%%%%%%%%%%%%
      
            
            if(z0==leaf || z1==leaf)  %if the sibling is a leaf, since no connections emerge from leaf, no cycles are formed, so no cycle check
                
                if(z0==leaf)    
                    leaf_sib= z1;
                else
                    leaf_sib= z0;
                end
                
                
                if(~ismember(leaf,intermediate_dag(1).v1(leaf_sib).succ))
                intermediate_dag(1).v1(leaf_sib).succ(end+1)=leaf;
                intermediate_dag(1).v1(leaf).pred(end+1)= leaf_sib;
                end
                
                %%% cut the bond btw parent and leaf after letting the
                %%%siblings bond
                intermediate_dag(1).v1(leaf).pred(intermediate_dag(1).v1(leaf).pred==z)=[];  %the leaf node must stay as leaf, unaffected by arti constr
                intermediate_dag(1).v1(z).succ(intermediate_dag(1).v1(z).succ==leaf)=[];
            
                
      %%%%%%%%%%%%%%%% when leaf is not in the children group  %%%%%%%%%%%%%%%
            else
                temp_sib_rcv=v;
                sibling_tocheck= [z0 z1];
                %%%%%%new change%%%%%%
                 [bond_formed_sib1,temp_checked_sib1] = is_siblingbondformed_func(temp_sib_rcv,sibling_tocheck,z);

                if(bond_formed_sib1)
                     intermediate_dag(1).v1 = temp_checked_sib1; 
                     [intermediate_dag(1).path_num,intermediate_dag(1).path_weight]=  paths_weights(intermediate_dag(1).v1);
                     intermediate_dag(1).load_diff_inter = max(intermediate_dag(1).path_weight)-min(intermediate_dag(1).path_weight);
                     intermediate_dag(1).paths_n = length(intermediate_dag(1).path_num);
                else
                      sibling_tocheck=fliplr(sibling_tocheck); %check if the flipped siblings cause cycles
                      [bond_formed_sib2,temp_checked_sib2] = is_siblingbondformed_func(temp_sib_rcv,sibling_tocheck,z);
                          if(bond_formed_sib2)
                             intermediate_dag(1).v1 = temp_checked_sib2; 
                             [intermediate_dag(1).path_num,intermediate_dag(1).path_weight]=  paths_weights(intermediate_dag(1).v1);
                             intermediate_dag(1).load_diff_inter = max(intermediate_dag(1).path_weight)-min(intermediate_dag(1).path_weight);
                             intermediate_dag(1).paths_n = length(intermediate_dag(1).path_num);
                          else
                              if (intermediate_dag(1).v1(z).succ>2)
                                    break_chain= false;
                                    for z0= 1: length(sorted_siblings)
                                        if (break_chain)
                                            break;
                                        end
                                        for z1= 3:length(sorted_siblings)
                                            sibling_tocheck= [z0 z1];
                                            [bond_formed_sib3,temp_checked_sib3] = is_siblingbondformed_func(temp_sib_rcv,sibling_tocheck,z);
                                            if(bond_formed_sib3)
                                                 intermediate_dag(1).v1 = temp_checked_sib3; 
                                                 [intermediate_dag(1).path_num,intermediate_dag(1).path_weight]=  paths_weights(intermediate_dag(1).v1);
                                                 intermediate_dag(1).load_diff_inter = max(intermediate_dag(1).path_weight)-min(intermediate_dag(1).path_weight);
                                                 intermediate_dag(1).paths_n = length(intermediate_dag(1).path_num);
                                                 break_chain=true;
                                                 break;
                                            end
                                        end
                                    end
                              else
                                  
                             intermediate_dag(1).v1 = v; %revert to original
                             intermediate_dag(1).v1(z).forbidden =1; 
                              end
                           end
                              
                                       
                 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%               
                end
                end
           end  %%%if empty siblings
            decision_func();
            end
    end
end
%end
                        
                          
                          
                              
                              
                              
                              
                                 
                                    
                                    
                                    
                               
                             
                       
                
                
   
    
    