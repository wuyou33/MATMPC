%% Initialize Data
function [input, data] = InitData(settings)

    nx = settings.nx;        % No. of states
    nu = settings.nu;        % No. of controls
    ny = settings.ny;        % No. of outputs (references)    
    nyN= settings.nyN;       % No. of outputs at terminal stage 
    np = settings.np;        % No. of parameters (on-line data)
    nc = settings.nc;        % No. of constraints
    ncN = settings.ncN;      % No. of constraints at terminal stage
    N  = settings.N;         % No. of shooting points
    nbx = settings.nbx;      % No. of state bounds
    nbu = settings.nbu;      % No. of control bounds
    nbu_idx = settings.nbu_idx;  % Index of control bounds

    switch settings.model
                      
        case 'InvertedPendulum'
            input.x0 = [0;pi;0;0];    
            input.u0 = zeros(nu,1);    
            para0 = 0;  

            Q=repmat([10 10 0.1 0.1 0.01]',1,N);
            QN=[10 10 0.1 0.1]';

            % upper and lower bounds for states (=nbx)
            lb_x = -2;
            ub_x = 2;

            % upper and lower bounds for controls (=nbu)           
            lb_u = -20;
            ub_u = 20;
                       
            % upper and lower bounds for general constraints (=nc)
            lb_g = [];
            ub_g = [];            
            lb_gN = [];
            ub_gN = [];

        case 'ChainofMasses_Lin'
            n=5;
            data.n=n;
            input.x0=zeros(nx,1);
            for i=1:n
                input.x0(i)=7.5*i/n;
            end
            input.u0=zeros(nu,1);
            para0=0;
            wv=[];wx=[];
            wu = [0.1 0.1 0.1];
            for i=1:3
                wx = [wx, 25];
                wv = [wv, 0.25*ones(1,n-1)];
            end
            Q = repmat([wx,wv,wu]',1,N);
            QN= [wx,wv]';

            % upper and lower bounds for states (=nbx)
            lb_x = [];
            ub_x = [];

            % upper and lower bounds for controls (=nbu)           
            lb_u = [-1;-1;-1];
            ub_u = [1;1;1];
                       
            % upper and lower bounds for general constraints (=nc)
            lb_g = [];
            ub_g = [];            
            lb_gN = [];
            ub_gN = [];

        case 'ChainofMasses_NLin'
            n=10;
            data.n=n;
            input.x0=[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1 zeros(1,nx-n)]';
            input.u0=zeros(nu,1);
            para0=0;
            wv=[];wx=[];
            wu=[0.01, 0.01, 0.01];
            for i=1:3
                wx=[wx,25];
                wv=[wv,ones(1,n-1)];
            end
            Q = repmat([wx,wv,wu]',1,N);
            QN= [wx,wv]';

            % upper and lower bounds for states (=nbx)
            lb_x = [];
            ub_x = [];

            % upper and lower bounds for controls (=nbu)           
            lb_u = [-1;-1;-1];
            ub_u = [1;1;1];
                       
            % upper and lower bounds for general constraints (=nc)
            lb_g = [];
            ub_g = [];            
            lb_gN = [];
            ub_gN = [];
                                       
        case 'TethUAV_param_1order_slack'
            
            input.x0=[0; 0; 0; 0; 9.81; 0];%zeros(nx,1);
            input.u0=[0; 0; 0; 0];%zeros(nu,1);%
            alpha = pi/6;
            para0=[-alpha; alpha];
            % phi phi_dot theta theta_dot 
            q = [200, 1, 200, 0, 0.0001, 0.0001, 1, 1, 1, 0, 5000, 5000];

            qN = q(1:nyN);
            Q = repmat(q',1,N);
            QN = qN';
            
            fR_min = 0;%-inf;
            fR_max = 15;%inf;
            tauR_min = -1.2;%-inf;
            tauR_max = 1.2;%inf;
            fL_min = 0;%-inf;
            fL_max = 10;%inf;
            constr_max = 0;
            constr_min = -inf;
            s1_min = 0;
            s1_max = inf;
            s2_min = 0;
            s2_max = inf;
            
            % upper and lower bounds for states (=nbx) if f1,2 are f_R, tau_R
            lb_x = [fR_min; tauR_min];%0*ones(nbx,1);
            ub_x = [fR_max; tauR_max]; %omegaMax*ones(nbx,1);
            
            % upper and lower bounds for controls (=nbu)           
            lb_u = [s1_min; s2_min];
            ub_u = [s1_max; s2_max];
                       
            % upper and lower bounds for general constraints (=nc)
            lb_g = [fL_min; constr_min; constr_min];
            ub_g = [fL_max; constr_max; constr_max];            
            lb_gN = [fL_min];
            ub_gN = [fL_max];  
                                                
    end

    % prepare the data
    
    input.lb = repmat(lb_g,N,1);
    input.ub = repmat(ub_g,N,1);
    input.lb = [input.lb;lb_gN];
    input.ub = [input.ub;ub_gN];
            
    lbu = -inf(nu,1);
    ubu = inf(nu,1);
    for i=1:nbu
        lbu(nbu_idx(i)) = lb_u(i);
        ubu(nbu_idx(i)) = ub_u(i);
    end
                
    input.lbu = repmat(lbu,1,N);
    input.ubu = repmat(ubu,1,N);
    
    input.lbx = repmat(lb_x,1,N);
    input.ubx = repmat(ub_x,1,N);

    x = repmat(input.x0,1,N+1);  % initialize all shooting points with the same initial state 
    u = repmat(input.u0,1,N);    % initialize all controls with the same initial control
    para = repmat(para0,1,N+1);  % initialize all parameters with the same initial para
        
    input.x=x;           % states and controls of the first N stages (nx by N+1 matrix)
    input.u=u;           % states of the terminal stage (nu by N vector)
    input.od=para;       % on-line parameters (np by N+1 matrix)
    input.W=Q;           % weights of the first N stages (ny by ny matrix)
    input.WN=QN;         % weights of the terminal stage (nyN by nyN matrix)
%     
    input.lambda=zeros(nx,N+1);   % langrangian multiplier w.r.t. equality constraints
    input.mu=zeros(N*nc+ncN,1);   % langrangian multipliers w.r.t. general inequality constraints
    input.mu_u = zeros(N*nu,1);   % langrangian multipliers w.r.t. input bounds
    input.mu_x = zeros(N*nbx,1);  % langrangian multipliers w.r.t. state bounds
    %% Reference generation

    switch settings.model

        case 'InvertedPendulum'

            data.REF=zeros(1,nx+nu);

        case 'ChainofMasses_Lin'

            data.REF=[7.5,0,0,zeros(1,3*(n-1)),zeros(1,nu)];

        case 'ChainofMasses_NLin'

            data.REF=[1,0,0,zeros(1,3*(n-1)),zeros(1,nu)];
                                                                
        case 'TethUAV_param_1order_slack'
        	data.REF = zeros(1, ny);
         
    end
    
end