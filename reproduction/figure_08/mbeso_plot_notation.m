function s=mbeso_plot_notation()
%MBESO_PLOT_NOTATION Symbols in manuscript Eqs. (5)-(6) and Fig. 8 note.
% Unicode prime and the precomposed eta-with-tilde glyph retain Times New Roman.
% U+1FC6 avoids MATLAB TeX misplacing a separate U+0303 combining accent.
% The superscript k on the history average is the update index.
s.stress_raw='σ_{e,i}';
s.stress_filtered='σ′_{e,i}';
s.eta_raw='η_i';
s.eta_filtered='η′_i';
s.eta_history=[char(8134) '_i^{k}'];
end
