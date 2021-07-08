# Contains graphs metrics

sqrtk(g) = mean(degree(g).^0.5)^2 / mean(degree(g)) for g in graphs_df.graph
cl(g) = mean betweenness_centrality