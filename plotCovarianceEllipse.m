function plotCovarianceEllipse(ax, mu, Sigma, p, color)

    s = -2 * log(1 - p);

    [V, D] = eig(Sigma * s);

    t = linspace(0, 2 * pi);
    a = (V * sqrt(D)) * [cos(t(:))'; sin(t(:))'];

    plot(ax, a(1, :) + mu(1), a(2, :) + mu(2), 'color', color);
    
end