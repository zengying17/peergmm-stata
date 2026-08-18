# peer_cra for Stata

`peer_cra` estimates endogenous peer effects under conditional random
assignment to peer groups within urns, or selection pools. It implements a
two-step GMM estimator with optional own-effect and peer-effect covariates and a
heteroskedasticity-robust, bias-corrected covariance estimator.

The command requires Stata 16 or newer.

## Installation

Installation is still under development. For now, copy these four files into your working directory:

```text
peer_cra.ado
peer_cra_p.ado
lpeergmm.mlib
peer_cra.sthlp
```

## Syntax

```stata
peer_cra depvar [if] [in], urn(varname) group(varname) ///
    [own(varlist) peer(varlist) lambda_bounds(# #) ranktol(#)]
```

- `urn()` identifies the urn or selection pool.
- `group()` identifies the peer group nested within the urn.
- `own()` lists covariates entering as own effects.
- `peer()` lists covariates entering as leave-one-out peer averages.

Run `help peer_cra` for all numerical options and stored results.

## Example

```stata
peer_cra Y, urn(urn_id) group(group_id) own(x1 x2) peer(x1)
```

The coefficient named `lambda` is the endogenous peer-effect parameter.
Coefficients prefixed by `ave_` correspond to leave-one-out peer averages.

## Stored results and prediction

`peer_cra` is an `eclass` command. It stores the coefficient vector in `e(b)`,
the covariance matrix in `e(V)` when covariance inference is available, the
estimation sample in `e(sample)`, sample counts, optimizer status, and the
inference-availability flag in `e()`.

After estimation, `predict` supports:

- `xb`: structural prediction without the urn fixed effect;
- `fitted`: full fitted value;
- `residuals`: structural residual;
- `alpha`: estimated urn fixed effect.

## Repository contents

- peer_cra.ado`: estimation command.
- peer_cra_p.ado`: postestimation `predict` command.
- lpeergmm.mlib`: compiled Mata library.
- peer_cra.sthlp`: Stata help file.

Keep all four files together. 

## Companion R package

The companion R implementation is available at
[zengying17/peergmm-r](https://github.com/zengying17/peergmm-r).

## Citation

Ying Zeng, *Estimation and Inference for Peer Effects under Conditional Random
Assignment*. Citation details will be updated when the paper is released.
