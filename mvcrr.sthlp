{smcl}
{* *! version 1.5.1  27aug2026}{...}
{viewerjumpto "Syntax" "mvcrr##syntax"}{...}
{viewerjumpto "Description" "mvcrr##description"}{...}
{viewerjumpto "Options" "mvcrr##options"}{...}
{viewerjumpto "Remarks: the reporting panel" "mvcrr##panel"}{...}
{viewerjumpto "Remarks: which effects enter" "mvcrr##effects"}{...}
{viewerjumpto "Remarks: fix() and the penalty" "mvcrr##fixrole"}{...}
{viewerjumpto "Remarks: small samples" "mvcrr##smallsamples"}{...}
{viewerjumpto "Remarks: single-replication mode" "mvcrr##srmode"}{...}
{viewerjumpto "Remarks: double counting" "mvcrr##remarks"}{...}
{viewerjumpto "Remarks: known limitations" "mvcrr##limitations"}{...}
{viewerjumpto "Remarks: deprecated" "mvcrr##deprecated"}{...}
{viewerjumpto "Examples" "mvcrr##examples"}{...}
{viewerjumpto "Stored results" "mvcrr##results"}{...}
{viewerjumpto "References" "mvcrr##reference"}{...}
{vieweralsosee "mvgstudy" "help mvgstudy"}{...}
{vieweralsosee "mvdstudy" "help mvdstudy"}{...}

{p2col:{bf:mvcrr}} Projected construct-relevant reliability after {helpb mvgstudy}: the covariance-inclusive reporting panel (CRR_zc, delta_beta, CRR, Jbar, Abar)  {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:mvcrr} {cmd:,} {opt o:bject(facetname)}
{cmd:(} {opt nf:acet(facetname # ...)} {cmd:|} {opt cur:rent} {cmd:)}
[{opt fix(facetname # ...)}
{opt a:var(varname)} {opt j:var(varname)} {opt p:var(varname)}
{opt nu0(#)} {opt nu1(#)} {opt nutt(#)} {opt sigmae(#)}
{opt pw:means} {opt b:ootstrap} {opt ci:_level(#)}]

{p 8 17 2}
{cmd:mvcrr} {cmd:,} {opt o:bject(facetname)} {opt nl(#)}
{opt nu0(#)} {opt nu1(#)} {opt nutt(#)}
{opt n0:var(varname)} {opt n1:var(varname)}
[{opt rho_lp(#)} {opt a:var(varname)} {opt j:var(varname)} {opt p:var(varname)}]
{space 4}{it:(single-replication mode)}

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt o:bject(facetname)}}object of measurement; must be a main effect of the design (required){p_end}
{synopt:{opt nf:acet(facetname # ...)}}D-study size for every random non-object facet{p_end}
{synopt:{opt cur:rent}}use the observed facet sizes as D-study sizes{p_end}
{synopt:{opt nl(#)}}deprecated synonym for {cmd:nfacet(}{it:facet} {it:#}{cmd:)} when one random facet remains; required in single-replication mode{p_end}
{synopt:{opt fix(facetname # ...)}}treat the named facets as fixed with the given sizes{p_end}
{synopt:{opt a:var(varname)} {opt j:var(varname)} {opt p:var(varname)}}which outcome is the intercept, the separation, the prevalence{p_end}
{syntab:Realization error}
{synopt:{opt sigmae(#)}}supply sigma2_eps directly{p_end}
{synopt:{opt nu0(#)} {opt nu1(#)} {opt nutt(#)}}closed-form sigma2_eps from pooled within-class variances and utterances per cell{p_end}
{syntab:Single-replication mode}
{synopt:{opt n0:var(varname)} {opt n1:var(varname)}}per-object gold-negative/-positive utterance counts{p_end}
{synopt:{opt rho_lp(#)}}lesson prevalence variance as a share of object prevalence variance; default {cmd:rho_lp(1)}{p_end}
{syntab:Means and inference}
{synopt:{opt pw:means}}person-weighted means of A, J, prevalence (mean of within-object means){p_end}
{synopt:{opt b:ootstrap}}BCa confidence intervals for the whole panel (requires {cmd:mvgstudy, bootstrap}){p_end}
{synopt:{opt ci:_level(#)}}confidence level; default {cmd:ci_level(95)}{p_end}
{synoptline}

{p 4 6 2}
{cmd:mvcrr} is a post-estimation command.  It requires a prior {cmd:mvgstudy}
run with {it:exactly three} outcome variables on any crossed/nested design
whose object of measurement is a main effect, for example{p_end}

{p 8 12 2}{cmd:. mvgstudy (Ahat Jhat pihat = p l|p)}{p_end}
{p 8 12 2}{cmd:. mvgstudy (Ahat Jhat pihat = p l r p#l p#r l#r p#l#r)}{p_end}
{p 8 12 2}{cmd:. mvgstudy (Ahat Jhat pihat = p)}{space 6}{it:(single-replication mode)}{p_end}

{p 4 6 2}
where, for each cell (e.g., person-lesson), {cmd:Ahat} is the estimated
negative-class (false-positive) intercept, {cmd:Jhat} the estimated class
separation, and {cmd:pihat} the estimated prevalence, computed upstream from
gold-labeled utterances.  Like {helpb mvdstudy}, {cmd:mvcrr} reads the
persistent Mata object {cmd:c}; run {cmd:mata drop c} when finished.


{marker description}{...}
{title:Description}

{pstd}
{cmd:mvcrr} computes the {it:projected construct-relevant reliability},

{p 8 8 2}
CRR = lambda x Erho2_DCF:O,

{pstd}
the share of observed object-score variance that is {it:both} reproducible
over the generalization facets {it:and} driven by true prevalence, evaluated
at the D-study sizes given by {opt nfacet()} (or {opt current}), under
differential classifier functioning (DCF) at every effect of the design.
The observed cell score is q = A + J*pi; every effect e of the design
carries a 3 x 3 covariance-component matrix Sigma_e over (A, J, pi)
estimated by {cmd:mvgstudy}, and the variance of q at effect e is

{p 8 8 2}
V(e) = w'Sigma_e w + S(e),{space 6}w = (1, mu_pi, Jbar)',

{pstd}
with S(e) the second-order term collecting the products j*pi whose facets
combine to effect e (the ordered-pair union rule of the derivation, Part
II.2).  The object effect O supplies the signal and the lambda penalty; every
other effect containing the object facet supplies error V(e)/d(e), where
d(e) is the product of the D-study sizes of the random facets in e; the
realization variance sigma2_eps is divided by the product of all random
non-object facet sizes.  Then

{p 8 8 2}
lambda = num_pi / V(O),{space 4}
Erho2_DCF:O = V(O) / [V(O) + sum_e V(e)/d(e) + sigma2_eps/d(eps)],{space 4}
CRR = lambda x Erho2_DCF:O.

{pstd}
Two definitions of the signal num_pi are reported side by side (see
{help mvcrr##panel:the reporting panel}): the {bf:zero-covariance}
definition num_pi = Jbar^2 * sigma2_pi, which ignores the off-diagonals of
every Sigma_e and reproduces version 1.4.0 exactly (labelled {bf:CRR_zc},
{cmd:r(crr_zc)}), and the {bf:covariance-inclusive} definition
num_pi = beta^2 * sigma2_pi with
beta = Jbar + (sigma_api + mu_pi*sigma_jpi)/sigma2_pi from the object-level
covariances (the orthogonal, or regression, decomposition), under which
lambda = corr(tau, pi)^2 exactly and CRR is the projected squared
correlation of the D-study score with true prevalence.  This second
coefficient is the estimand and is labelled simply {bf:CRR} ({cmd:r(crr)}),
matching the notation of the dissertation.

{pstd}
Because the intercept Abar cancels from every variance ratio yet biases
absolute prevalence estimates directly, CRR is always reported together with
Abar; treat a low intercept as a companion requirement whenever absolute
prevalence, rather than relative standing, is the reported quantity.

{pstd}
Negative variance-component estimates are truncated at zero (with a note).
On the zero-covariance path only the diagonal is truncated; on the
orthogonal path the whole row and column of a truncated component are
zeroed and the matrix is repaired to positive semidefinite by eigenvalue
clipping (the number of repaired matrices is reported and stored).  If
truncation removes both object-level DCF components, lambda_zc = 1 by
construction and CRR_zc is an {it:upper bound}, not an estimate.

{pstd}
Requires Stata 19 or later.  No dependencies outside official Stata (the
Mata engine ships compiled in {cmd:lmvgstudy.mlib}).


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt object(facetname)} specifies the object of measurement (e.g., {cmd:p}).
It must be a facet of the design {it:and} appear as a main effect in the
{cmd:mvgstudy} termlist.  Required.  Exits with error 198 otherwise.

{phang}
{opt nfacet(facetname # ...)} gives the D-study sample size of every random
non-object facet as alternating facet names and positive integers, e.g.,
{cmd:nfacet(l 4)} or {cmd:nfacet(l 4 r 2)}.  Every random non-object facet
(after {opt fix()}) must receive a size; a facet named in {opt fix()} may not
also appear here.  Exactly one of {opt nfacet()} and {opt current} is
required (unless every non-object facet is fixed, in which case neither is
needed).

{phang}
{opt current} uses the observed G-study facet sizes (for unbalanced designs,
the number of observed levels, as {helpb mvdstudy} does) as the D-study
sizes.  May not be combined with {opt nfacet()}.

{phang}
{opt nl(#)} is retained as a deprecated synonym for {cmd:nfacet(}{it:facet}
{it:#}{cmd:)} when exactly one random non-object facet remains; a note reports
the interpretation.  In {help mvcrr##srmode:single-replication mode} it is the
planned number of lessons and is required.  May not be combined with
{opt nfacet()} or {opt current}.

{phang}
{opt fix(facetname # ...)} treats the named facets as fixed at the given
sizes, applying the mixed-design augmentation of Brennan (2001, Ch. 4)
before anything is computed: the components of every effect containing a
fixed facet are added, divided by the fixed sizes, to the effect with those
facets removed, and the fixed facets leave the design.  Identical to the
{opt fix()} option of {helpb mvdstudy}; the original design is restored
before {cmd:mvcrr} exits, also on error.  See
{help mvcrr##fixrole:fix() and the penalty}.  Not available in
single-replication mode.

{phang}
{opt avar(varname)}, {opt jvar(varname)}, {opt pvar(varname)} identify which
outcome variable is the intercept (A), the separation (J), and the prevalence.
Defaults: the first, second, and third variable of the {cmd:mvgstudy} varlist.
The three must be distinct.

{dlgtab:Realization error}

{phang}
{opt sigmae(#)} supplies the mean realization variance sigma2_eps directly.
Must be nonnegative.  May not be combined with {opt nu0()}/{opt nu1()}/{opt nutt()}.

{phang}
{opt nu0(#)}, {opt nu1(#)}, {opt nutt(#)} compute sigma2_eps by the closed
form

{p 12 12 2}
sigma2_eps = [ mupi*nu1 + (1-mupi)*nu0 + mupi*(1-mupi)*Jbar^2 ] / nutt

{pmore}
with {opt nu0(#)} and {opt nu1(#)} the pooled within-class score variances
(nu_0^2, nu_1^2; nonnegative) and {opt nutt(#)} the planned utterances per
cell (positive).  All three must be given together.  sigma2_eps is divided
by d(eps), the product of the D-study sizes of all random non-object facets
(n_L for the p, l|p design; n_L x n_R for p x l x r).

{pmore}
{it:Default when neither is specified:} sigma2_eps = 0.  See
{help mvcrr##remarks:double counting}.

{dlgtab:Single-replication mode}

{phang}
{opt n0var(varname)}, {opt n1var(varname)} ({it:single-replication mode only;}
{it:required there}) name the per-object counts of gold-negative and
gold-positive utterances, read from the dataset in memory (which must still
hold the estimation sample).  They drive the sampling-error disattenuation of
the object-level components.

{phang}
{opt rho_lp(#)} ({it:single-replication mode only}) sets the
lesson-within-object prevalence variance as a proportion of the object-level
prevalence variance, sigma2_pi_LP = rho_lp x sigma2_pi.  Default is
{cmd:rho_lp(1)}, the dissertation's value.

{dlgtab:Means and inference}

{phang}
{opt pwmeans} computes Abar, Jbar, and mu_pi as {it:person-weighted} means —
the mean over objects of measurement of the within-object means — instead of
the default observation-weighted grand mean over all rows.  The two are
identical when the design is balanced.  Under unbalance the default grand
mean weights objects by the number of rows they contribute; specify
{opt pwmeans} to weight every object equally.  The option propagates through
{opt bootstrap} (per-replicate person-weighted means are stored by
{cmd:mvgstudy}'s bootstrap for the first facet of the first effect, so
{opt object()} must be that facet when both options are combined).  The means
definition in use is always shown in the output and stored in {cmd:r(pwmeans)}.

{phang}
{opt bootstrap} computes bootstrap BCa confidence intervals for every member
of the panel and its companions (CRR_zc, delta_beta, CRR, Jbar, Abar,
lambda_zc, lambda, both Erho2 values).  Requires that {cmd:mvgstudy} was run
with its {opt bootstrap} option: {cmd:mvcrr} propagates the stored G-study
bootstrap and jackknife replicates — the full covariance-component matrices
{it:and} the per-replicate outcome means — through the same computation
core, re-applying {opt fix()} per replicate, so no additional resampling is
performed and the option adds essentially no runtime.  Not available in
single-replication mode.

{phang}
{opt ci_level(#)} sets the confidence level for the bootstrap intervals;
default is {cmd:ci_level(95)}.  Must be strictly between 0 and 100.


{marker panel}{...}
{title:Remarks: the reporting panel}

{pstd}
No single coefficient survives on its own, so {cmd:mvcrr} always displays and
stores the following five-member panel (spec rev. 3.2; validated by
Simulation 4 of the dissertation).  The panel is displayed in its reading
order: rank, check, estimate, companions.

{phang2}
1. {bf:CRR_zc} — the zero-covariance coefficient (the version 1.4.0 formulas;
{cmd:r(crr_zc)}).  The {it:ranking statistic}: magnitude-aware
(its signal is Jbar^2 sigma2_pi, so a classifier with no separation cannot
pass), stable at small object samples, and exact when delta_beta = 0.
Whenever delta_beta differs from zero it is computed under a stated
no-saturation assumption — an upper-bound-flavored screen, not the estimand.

{phang2}
2. {bf:delta_beta} = beta - Jbar ({cmd:r(dbeta)}) — the per-configuration
{it:assumption check}, signed, in Jbar units.  delta_beta ~ 0: the two
definitions coincide and CRR_zc is exact.  delta_beta < 0 (saturation, e.g., a
classifier that separates worse at high prevalence): CRR_zc is optimistic.
delta_beta > 0: lambda under the covariance-inclusive definition borrows
population-specific alignment that will not transport.  Unbiased but noisy
at small samples (sampling SD about .15 to .2 at 12 objects in Simulation 4,
smaller as objects grow): a sign pattern across configurations is
informative, a single value is not.

{phang2}
3. {bf:CRR} ({cmd:r(crr)}) — the covariance-inclusive coefficient: the
{it:point estimate} of the estimand, the projected squared correlation of
the D-study score with true prevalence, computed under the orthogonal
decomposition (lambda = corr(tau, pi)^2).  At realistic signal it is nearly
unbiased even with 12 objects (Simulation 4 v2, reference cell with
sigma_pi = .07 and CRR_zc = .55: bias -.02 to -.04 for delta_beta between
-.26 and +.26 at 12 objects, within .01 at 50), and biased upward only where
the true value is near zero (truth .09, mean estimate .15 at 12 objects).
Its sampling SD at 12 objects is of the same order as CRR_zc's (about .15),
so read it as a point estimate and use {opt bootstrap} for intervals.  It is
unsafe as a ranking statistic on its own because of variance cancellation:
large anti-tracking DCF can shrink V(O) toward zero and push a near-useless
classifier's corr(tau, pi)^2 high — which is why Jbar is a companion.

{phang2}
4. {bf:Jbar} ({cmd:r(Jbar)}) — the separation companion.  A floor on Jbar
guards the correlation-type members against the cancellation pathology: a
unit-free ratio cannot see that nothing is left of the signal in score units.

{phang2}
5. {bf:Abar} ({cmd:r(Abar)}) — the intercept companion, required reading
whenever absolute prevalence is the reported quantity.

{pstd}
{bf:Selection guidance.}  Rank on CRR_zc against the use-determined floor,
require the Jbar floor, inspect delta_beta for the survivors — a large
negative delta_beta flags a configuration as failing the assumption its
CRR_zc rests on — and require that CRR also clear the floor for the selected set.  Among
configurations with similar CRR_zc, prefer the one with
delta_beta closest to zero: it is the better instrument, the one whose
reported reliability means what it says in any population, not just the
validation sample.

{pstd}
The companion quantities lambda_zc, lambda = corr(tau, pi)^2, beta, both
Erho2 values (zero-covariance and covariance-inclusive), the per-effect
component tables and the per-effect error contributions are displayed and
stored as well (see {help mvcrr##results:Stored results}).  Version 1.5.0
additionally displayed a Wishart bias-corrected coefficient CRR_bc as the
lower edge of a "sensitivity bracket" [CRR_bc, CRR]; Simulation 4 v2 showed
that at realistic signal both edges fall below the truth (CRR_bc by -.15 to
-.27 at 12 objects), so the bracket was withdrawn in 1.5.1 (see
{help mvcrr##deprecated:Deprecated}).


{marker effects}{...}
{title:Remarks: which effects enter, and how}

{pstd}
Ahat and Jhat are classifier-functioning parameters by construction, so all
of their variance at every effect is DCF; where it enters is determined by
the design and by two things the user already specifies:

{phang2}
o {opt object()}: A/J components at the object effect (after {opt fix()}
augmentation) enter the lambda penalty — contamination no amount of further
sampling averages away.

{phang2}
o the random/fixed status of every other facet ({opt nfacet()} vs
{opt fix()}): A/J components at random generalization effects enter the
error term, divided by that effect's D-study divisor, and shrink as sampling
increases.

{pstd}
Following the relative-error convention of {helpb mvdstudy}
({cmd:errortype(relative)}), only effects that contain the object facet
contribute error; main effects and interactions of the other facets alone
shift every object equally and do not affect relative standing.  Their
components still matter through the second-order terms: the product of a
J-component at effect e1 and a pi-component at effect e2 varies over the
union of their facets and is assigned to that union effect.  The design's
termlist must therefore be a complete decomposition (every union of two
effects is itself an effect); {cmd:mvcrr} exits with error 198 otherwise.
For the p, l|p design this rule reproduces version 1.4.0 exactly: the error
is a(L:P) + (Jbar^2 + j(P)) pi(L:P) + j(L:P)(mu_pi^2 + pi(P) + pi(L:P)) plus
the covariance terms.


{marker fixrole}{...}
{title:Remarks: fix() and the penalty}

{pstd}
The lambda penalty and the facet-error term both lower CRR, but differently:
the penalty caps lambda permanently, while facet error is divided by the
D-study sizes and washes out as sampling grows.  The partition between them
is not a per-effect switch; it follows from the universe of generalization
the user declares.  Consider persons x lessons x raters with
{cmd:object(p)}:

{phang2}
o {bf:lessons random} ({cmd:nfacet(l 4 r 2)}): the A/J components at p#l,
p#r and p#l#r sit in the error term, divided by n_L, n_R and n_L x n_R.
Only the p components enter the penalty.  Right when lessons are sampled
occasions from a broader universe.

{phang2}
o {bf:lessons fixed} ({cmd:fix(l 4) nfacet(r 2)}): the augmentation folds
the lesson-indexed components upward; p#l joins p (and thereby the penalty),
p#l#r joins p#r.  Right when the universe {it:is} those particular lessons.

{pstd}
A user who wants lesson-to-lesson DCF to count against lambda expresses that
as a statement about the universe ({opt fix()}), never as a per-effect
designation; there is deliberately no option to move individual components
between penalty and error.


{marker smallsamples}{...}
{title:Remarks: small samples}

{pstd}
Whenever the number of objects is below 50, {cmd:mvcrr} prints a warning.
Simulation 4 (v2, reference cell calibrated to the empirical survivors:
mu_pi = .20, sigma_pi = .07, Jbar = .55, CRR_zc = .55) measured the sampling
behavior of the panel at 12 and 50 objects: CRR is nearly unbiased at
realistic signal (-.02 to -.04 at 12 objects, within .01 at 50; upward only
where the truth is near zero) with a sampling SD of about .15 at 12 objects,
PSD repair fires in a sizeable share of replicates, and delta_beta is
unbiased but weakly powered (SD about .2 at 12 objects).  Point estimates at
validation-sample sizes are screening values; the {opt bootstrap} interval
is the reportable inference.  (The +.07 to +.11 upward bias of the
covariance-inclusive estimator reported for 1.5.0 came from Simulation 4 v1,
whose reference cell had sigma_pi = .03 and CRR about .15; it was a
low-signal artifact.)


{marker srmode}{...}
{title:Remarks: single-replication mode}

{pstd}
When the G study has the one-effect design {it:(A J prev = object)} — one row
per object of measurement, no lesson replication (e.g., a validation subsample
with all of a teacher's coded utterances pooled into a single set) — the
lesson-within-object components cannot be estimated, and {cmd:mvcrr} switches
to single-replication mode.  It then computes the dissertation's person-only
criterion, CRR = lambda x {it:Erho2_DCF:P}, with the full panel: the
across-object covariance matrix of Ahat, Jhat, and the prevalence (from
{cmd:emcp1}) is {it:disattenuated} by subtracting the mean per-object
sampling covariance matrix — nu0^2*mean(1/n0) for the intercept,
nu1^2*mean(1/n1) + nu0^2*mean(1/n0) for the separation, -nu0^2*mean(1/n0)
for their covariance, and the binomial mean(pi(1-pi)/n) for the prevalence
(the prevalence covariances are structurally zero) — then processed exactly
as in standard mode.  The lesson side enters as D-study parameters
(sigma2_pi_LP = {opt rho_lp(#)} x sigma2_pi, lesson-level DCF components 0)
and sigma2_eps by the {opt nu0()}/{opt nu1()}/{opt nutt()} closed form, which
is {it:required} in this mode ({opt sigmae()} is not allowed, and there is no
double-counting concern because no lesson-level components are estimated).
{opt bootstrap} and {opt fix()} are not available in this mode; {opt pwmeans}
is a no-op (one row per object) and is ignored with a note.  The coefficient
is returned as {cmd:r(erho2_dcfp)}, and the sampling-variance corrections as
{cmd:r(sampvar)}.


{marker remarks}{...}
{title:Remarks: double-counting of utterance-sampling noise}

{pstd}
When the generalization-facet components are estimated from per-cell
Ahat/Jhat/pihat values, those inputs already carry within-cell
(utterance-sampling) error, so the estimated components {it:absorb} the
noise that the formula's separate sigma2_eps term represents.  Supplying a
nonzero sigma2_eps on top of raw components counts that noise twice.

{pstd}
{cmd:mvcrr} therefore defaults to sigma2_eps = 0: the noise travels inside the
estimated components instead.  Both live in the same error block, so the
total error budget is approximately preserved; the residual distortion is
slightly conservative (CRR-lowering), which is the safe direction for a
selection criterion.

{pstd}
Users who have {it:disattenuated} their per-cell estimates upstream should
supply {opt sigmae(#)} or the {opt nu0()}/{opt nu1()}/{opt nutt()} closed form
to restore the textbook decomposition.  Specifying either signals that the
components are noise-free, and a note to that effect is printed.  The
resolved sigma2_eps, its source, and its divisor are always displayed and
stored, so every reported CRR is reproducible from its stated inputs.


{marker limitations}{...}
{title:Remarks: known limitations}

{phang2}
o Effects other than the object main effect that are confounded with the
object (e.g., an object nested in a group facet, {cmd:p|g}) are not
supported: {opt object()} must be a main effect.

{phang2}
o Single-replication mode has no {opt bootstrap} (propagating the
disattenuation through resampled objects would need per-replicate count
data) and no {opt fix()}.

{phang2}
o The second-order terms assume within-effect normality; under skewed
prevalence the error is about .01 (Simulation 4, skew arm).


{marker deprecated}{...}
{title:Remarks: deprecated}

{pstd}
{cmd:biascorrect} (undocumented in the syntax diagram; removal planned for
version 1.6) restores the Wishart-moment bias-corrected coefficient of
version 1.5.0: CRR_bc subtracts the closed-form plug-in of Var(Chat) from
Chat^2, Chat = Jbar sigma2_pi + sigma_api + mu_pi sigma_jpi (derivation
I.8; floored at 0 and capped at V(O)).  The plug-in is exact for balanced
designs and approximate (with a note) for unbalanced ones.  Simulation 4 v2
showed the estimator to be uniformly over-conservative at realistic signal
(-.15 to -.27 at 12 objects, -.05 at 50), so it is no longer part of the
panel.  With the option, one extra display line appears, {cmd:r(crr_bc)},
{cmd:r(lambda_bc)}, and {cmd:r(varC)} are returned, and two rows
({cmd:crr_bc}, {cmd:lambda_bc}) are appended to {cmd:r(crr_table)}; without
it they are not returned at all.  The option exists so that the regression
tests against the Simulation 4 reference implementation remain reproducible.

{pstd}
{cmd:r(crr_orth)}, {cmd:r(lambda_orth)}, and {cmd:r(erho2_orth)} are kept
as aliases of {cmd:r(crr)}, {cmd:r(lambda)}, and {cmd:r(erho2_cov)} for the
1.5.x releases and will be removed in 1.6.


{marker examples}{...}
{title:Examples}

{pstd}Both example datasets are installed by {cmd:net get mvgstudy}; their
generators ({cmd:gen_mvcrrexampledata.do}, {cmd:gen_mvcrrexampledata_plr.do})
with the population parameters are in the package repository.  The examples
are clickable and self-contained in the order shown.{p_end}

{pstd}Standard two-effect design, projected to four lessons (reproduces
version 1.4.0):{p_end}

{phang}{stata use mvcrrexampledata.dta, clear}{p_end}
{phang}{stata mvgstudy (Ahat Jhat pihat = p l|p)}{p_end}
{phang}{stata mvcrr, object(p) nfacet(l 4)}{p_end}

{pstd}Observed facet sizes, and the deprecated synonym:{p_end}

{phang}{stata mvcrr, object(p) current}{p_end}
{phang}{stata mvcrr, object(p) nl(4)}{p_end}

{pstd}Closed-form realization variance for disattenuated inputs
(nu_0^2 = .01, nu_1^2 = .02, 150 utterances per lesson):{p_end}

{phang}{stata mvcrr, object(p) nfacet(l 4) nu0(.01) nu1(.02) nutt(150)}{p_end}

{pstd}Bootstrap BCa confidence intervals for the panel (G study must be
bootstrapped first):{p_end}

{phang}{stata mvgstudy (Ahat Jhat pihat = p l|p), bootstrap reps(1000) seed(90210)}{p_end}
{phang}{stata mvcrr, object(p) nfacet(l 4) bootstrap}{p_end}

{pstd}Weighting every teacher equally in the means (identical to the default
on this balanced corpus; differs under unequal lessons per teacher):{p_end}

{phang}{stata mvcrr, object(p) nfacet(l 4) pwmeans}{p_end}
{phang}{stata mvcrr, object(p) nfacet(l 4) pwmeans bootstrap}{p_end}

{hline}

{pstd}Crossed persons x lessons x raters design ({cmd:mvcrrexampledata_plr.dta},
200 x 6 x 3, generated with zero within-effect covariances so delta_beta ~ 0;
true CRR_zc at four lessons and two raters is about .24); lessons random,
then lessons fixed (their DCF joins the lambda penalty):{p_end}

{phang}{stata use mvcrrexampledata_plr.dta, clear}{p_end}
{phang}{stata mvgstudy (Ahat Jhat pihat = p l r p#l p#r l#r p#l#r)}{p_end}
{phang}{stata mvcrr, object(p) nfacet(l 4 r 2)}{p_end}
{phang}{stata mvcrr, object(p) nfacet(r 2) fix(l 4)}{p_end}

{hline}

{pstd}Single-replication mode (one pooled utterance set per teacher; shown
for syntax — requires your own one-row-per-object data with count variables):{p_end}

{phang}{cmd:. mvgstudy (Ahat Jhat pihat = tid)}{p_end}
{phang}{cmd:. mvcrr, object(tid) nl(4) nu0(.01) nu1(.02) nutt(150) n0var(n0) n1var(n1)}{p_end}

{pstd}Clean up when finished:{p_end}

{phang}{stata mata drop c}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:mvcrr} stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(crr)}}CRR, the covariance-inclusive projected construct-relevant reliability (point estimate of the estimand; was the zero-covariance value in 1.5.0){p_end}
{synopt:{cmd:r(crr_zc)}}CRR_zc, the zero-covariance coefficient (ranking statistic){p_end}
{synopt:{cmd:r(Abar)}}mean false-positive intercept Abar{p_end}
{synopt:{cmd:r(Jbar)}}mean class separation Jbar{p_end}
{synopt:{cmd:r(dbeta)}}alignment diagnostic delta_beta = beta - Jbar{p_end}
{synopt:{cmd:r(beta)}}slope of the universe score on true prevalence{p_end}
{synopt:{cmd:r(lambda)}}lambda = corr(tau, pi)^2, covariance-inclusive (was the zero-covariance value in 1.5.0){p_end}
{synopt:{cmd:r(lambda_zc)}}lambda_zc, prevalence-driven share of universe-score variance, zero-covariance{p_end}
{synopt:{cmd:r(erho2)}}Erho2_DCF:O, zero-covariance path{p_end}
{synopt:{cmd:r(erho2_cov)}}Erho2_DCF:O, covariance-inclusive path{p_end}
{synopt:{cmd:r(erho2_dcfpl)}}same as {cmd:r(erho2)} (standard mode; name kept for compatibility){p_end}
{synopt:{cmd:r(erho2_dcfp)}}same as {cmd:r(erho2)} (single-replication mode; replaces {cmd:r(erho2_dcfpl)}){p_end}
{synopt:{cmd:r(mupi)}}mean prevalence{p_end}
{synopt:{cmd:r(sigmae)}}resolved sigma2_eps{p_end}
{synopt:{cmd:r(d_eps)}}divisor applied to sigma2_eps{p_end}
{synopt:{cmd:r(nl)}}n_L (single-replication mode, or when {opt nl()} was given){p_end}
{synopt:{cmd:r(rho_lp)}}(single-replication mode) rho_lp used{p_end}
{synopt:{cmd:r(n_obj)}}number of objects of measurement{p_end}
{synopt:{cmd:r(pwmeans)}}1 if person-weighted means were used, 0 otherwise{p_end}
{synopt:{cmd:r(trunc)}}number of components truncated at zero{p_end}
{synopt:{cmd:r(psdfix)}}number of component matrices PSD-repaired on the covariance-inclusive path{p_end}
{synopt:{cmd:r(ub)}}1 if object-level DCF fully truncated (CRR_zc is an upper bound){p_end}
{synopt:{cmd:r(var_obj_zc)}, {cmd:r(var_obj_orth)}}V(O) on the zero-covariance and covariance-inclusive paths{p_end}
{synopt:{cmd:r(err_zc)}, {cmd:r(err_orth)}}total error (facet error + sigma2_eps/d(eps)) on the two paths{p_end}
{synopt:{cmd:r(crr_orth)}, {cmd:r(lambda_orth)}, {cmd:r(erho2_orth)}}deprecated aliases of {cmd:r(crr)}, {cmd:r(lambda)}, {cmd:r(erho2_cov)}; removed in 1.6{p_end}
{synopt:{cmd:r(crr_bc)}, {cmd:r(lambda_bc)}, {cmd:r(varC)}}({cmd:biascorrect} only; deprecated) Wishart bias-corrected CRR and lambda, and the plug-in Var(Chat); {cmd:r(crr_bc)} missing if the plug-in is unavailable{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(object)}}object of measurement{p_end}
{synopt:{cmd:r(nfacet)}}resolved D-study sizes, as {it:facet # ...}{p_end}
{synopt:{cmd:r(fix)}}the {opt fix()} specification, if any{p_end}
{synopt:{cmd:r(avar)}, {cmd:r(jvar)}, {cmd:r(pvar)}}variables used as A, J, prevalence{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(components)}}effects x 3 variance components as used on the
zero-covariance path (post-truncation); rows are the effects that enter
(object first), columns A, J, prevalence{p_end}
{synopt:{cmd:r(covcomps)}}effects x 6 components as used on the covariance-inclusive
path (post-truncation, PSD-repaired): var_A, var_J, var_pi, cov_AJ, cov_Api,
cov_Jpi{p_end}
{synopt:{cmd:r(errors)}}error effects x 3: divisor d(e), V(e)/d(e) on the
zero-covariance and on the covariance-inclusive path (absent if no error effect remains){p_end}
{synopt:{cmd:r(crr_table)}}({opt bootstrap} only) 9 x 4 bootstrap summary:
rows crr_zc, dbeta, crr, Jbar, Abar, lambda_zc, lambda, erho2_zc, erho2_cov;
columns estimate, se, ci_lo, ci_hi (11 x 4 with {cmd:biascorrect}: rows
crr_bc, lambda_bc appended){p_end}
{synopt:{cmd:r(sampvar)}}(single-replication mode) 1 x 3 mean per-object
sampling variances subtracted in the disattenuation{p_end}


{marker reference}{...}
{title:References}

{pstd}
Brennan, R. L. (2001). {it:Generalizability theory}. Springer.

{pstd}
Erickson, S.  Dissertation, chapter 2: reliability of LLM-classifier-based
observational measures under differential classifier functioning (DCF).
CRR, the DCF-extended generalizability coefficients, the covariance-inclusive
derivation and Simulation 4 are defined there.

{pstd}
Li, G., Michaelides, M. P., & Haertel, E. (2023). Bootstrap confidence intervals for generalizability theory variance components. {it:PLOS ONE}, 18(7), e0288069.


{title:Also see}

{psee}
{helpb mvgstudy}, {helpb mvdstudy}
