% Script to test the spatial convergence rate
% for a smooth solution of the linear advection 
% equation

clear all;
close all;

% remove all useless files
system('rm -rf *.dat *.inp *.log INIT');

fprintf('Spatial convergence test on a smooth solution ');
fprintf('to the linear advection equation.\n');

% Ask for path to HyPar source directory
hypar_path = input('Enter path to HyPar source: ','s');

% Add to MATLAB path
path(path,strcat(hypar_path,'/Examples/Matlab/'));

% Compile the code to generate the initial solution
cmd = ['gcc ',hypar_path, ...
       '/Examples/1D/LinearAdvection/SineWave/aux/init.c ', ...
       'lm -o INIT'];
system(cmd);
% find the HyPar binary
hypar = [hypar_path,'/bin/HyPar'];

% Get the default
[~,~,~,~,~,~,~,~,~,hyp_flux_split,hyp_int_type,par_type,par_scheme,~, ...
 cons_check,screen_op_iter,file_op_iter,~, ip_type,input_mode, ...
 output_mode,n_io,op_overwrite,~,nb,bctype,dim,face,limits, ...
 mapped,borges,yc,nl,eps,p,rc,xi,wtol,lutype,norm,maxiter,atol,rtol, ...
 verbose] = SetDefaults();

% set problem specific input parameters
ndims = 1;
nvars = 1;
iproc = 1;
ghost = 3;

% specify spatial discretization scheme
hyp_scheme = [ ...
                'muscl3 ';
                'weno5  ';
                'crweno5'
             ];
schemes = 1:size(hyp_scheme,1);

% for spatial convergence, use very small time step
dt = 0.0001;
t_final = 1.0;
niter = int32(t_final/dt);

% set physical model and related parameters
model = 'linear-advection-diffusion-reaction';
adv = 1.0;

% set time-integration scheme
ts = 'rk';
tstype = '44';

petsc_flags = ' ';
% set PETSc time-integration flags (comment to turn off)
% petsc_flags = [petsc_flags, '-use-petscts '];
% petsc_flags = [petsc_flags, '-ts_type ',ts,' '];
% petsc_flags = [petsc_flags, '-ts_',ts,'_type ',tstype,' '];
% petsc_flags = [petsc_flags,' -ts_dt ',num2str(dt,'%1.16e'),' '];
% petsc_flags = [petsc_flags,' -ts_final_time ',num2str(t_final,'%f'),' '];
% petsc_flags = [petsc_flags,' -ts_max_steps ',num2str(100*niter,'%d'),' '];
% petsc_flags = [petsc_flags, '-ts_adapt_type none '];
% petsc_flags = [petsc_flags, '-hyperbolic_implicit '];
% petsc_flags = [petsc_flags, '-snes_type newtonls '];
% petsc_flags = [petsc_flags, '-snes_rtol 1e-10 '];
% petsc_flags = [petsc_flags, '-snes_atol 1e-10 '];
% petsc_flags = [petsc_flags, '-ksp_type gmres '];
% petsc_flags = [petsc_flags, '-ksp_rtol 1e-10 '];
% petsc_flags = [petsc_flags, '-ksp_atol 1e-10 '];
% petsc_flags = [petsc_flags, '-log_summary'];

% turn off solution output to file
op_format = 'none';

% set number of grid refinement levels
ref_levels = 5;

% set the commands to run the executables
nproc = 1;
for i = 1:max(size(iproc))
    nproc = nproc * iproc(i);
end
init_exec = './INIT > init.log 2>&1';
hypar_exec = ['$MPI_DIR/bin/mpiexec -n ',num2str(nproc),' ',hypar, ...
               ' ',petsc_flags,' > run.log 2>&1'];
clean_exec = 'rm -rf *.inp *.dat *.log';

% open figure window
scrsz    = get(0,'ScreenSize');
figErrDx = figure('Position',[1 scrsz(4)/2 scrsz(3)/2 scrsz(4)/2]);
figErrWt = figure('Position',[1 scrsz(4)/2 scrsz(3)/2 scrsz(4)/2]);

% initialize legend string
legend_str = char(zeros(size(schemes,2),size(hyp_scheme,2)));

% plotting styles
style = [ ...
            '-ko';
            '-ks';
            '-k^';
            '-kd';
            '-kv';
        ];
if (size(style,1) < size(schemes,2))
    printf('Error: not enough plotting styles specified.\n');
    return;
end

% run convergence test for each of the schemes
MinErr  = zeros(size(schemes,1));
MaxErr  = zeros(size(schemes,1));
MinCost = zeros(size(schemes,1));
MaxCost = zeros(size(schemes,1));
count = 1;
for j=schemes
    
    % set initial grid size;
    N = 20;
    
    % set legend entry
    legend_str(count,:) = hyp_scheme(j,:);
    
    % preallocate arrays for dx, error and wall times
    dx = zeros(ref_levels,1);
    Errors = zeros(ref_levels,3);
    Walltimes = zeros(ref_levels,2);

    % convergence analysis
    for r = 1:ref_levels
        dx(r) = 1.0 / N;
        fprintf('\t%s  %2d:  N=%-5d   dx=%1.16e\n',hyp_scheme(j,:), ...
                r,N,dx(r));
        % Write out the input files for HyPar
        WriteSolverInp(ndims,nvars,N,iproc,ghost,niter,ts,tstype, ...
            hyp_scheme(j,:),hyp_flux_split,hyp_int_type,par_type,par_scheme, ...
            dt,cons_check,screen_op_iter,file_op_iter,op_format,ip_type, ...
            input_mode,output_mode,n_io,op_overwrite,model);
        WriteBoundaryInp(nb,bctype,dim,face,limits);
        WritePhysicsInp_LinearADR(adv);
        WriteWenoInp(mapped,borges,yc,nl,eps,p,rc,xi,wtol);
        WriteLusolverInp(lutype,norm,maxiter,atol,rtol,verbose);
        % Generate the initial and exact solution
        system(init_exec);
        system('ln -sf initial.inp exact.inp');
        % Run HyPar
        system(hypar_exec);
        % Read in the errors
        [Errors(r,:),Walltimes(r,:)] = ReadErrorDat(ndims);
        % Clean up
        system(clean_exec);
        % increase grid size
        N = 2*N;
    end
    
    MinErr(j)  = min(Errors(:,2));
    MaxErr(j)  = max(Errors(:,2));
    MinCost(j) = min(Walltimes(:,1));
    MaxCost(j) = max(Walltimes(:,1));

    % plot L2 errors vs dx
    figure(figErrDx);
    loglog(dx,Errors(:,2),style(count,:),'linewidth',2,'MarkerSize',10);
    hold on;
    % plot L2 errors vs wall time
    figure(figErrWt);
    loglog(Walltimes(:,1),Errors(:,2),style(count,:),'linewidth',2, ...
           'MarkerSize',10);
    hold on;
        
    count = count+1;
end  

figure(figErrDx);
xlabel('dx','FontName','Times','FontSize',20,'FontWeight','normal');
ylabel('Error (L_2)','FontName','Times','FontSize',20,'FontWeight','normal');
set(gca,'FontSize',14,'FontName','Times');
legend(legend_str,'Location','northwest');
axis([min(dx)/2.0 2.0*max(dx) min(MinErr)/2.0 2.0*max(MaxErr)]);
grid on;
hold off;

figure(figErrWt);
xlabel('Wall time (seconds)','FontName','Times','FontSize',20, ...
       'FontWeight','normal');
ylabel('Error (L_2)','FontName','Times','FontSize',20,'FontWeight','normal');
set(gca,'FontSize',14,'FontName','Times');
legend(legend_str,'Location','northeast');
axis([min(MinCost)/2.0 2.0*max(MaxCost) min(MinErr)/2.0 2.0*max(MaxErr)]);
grid on;
hold off;

% clean up
system('rm -rf INIT');

