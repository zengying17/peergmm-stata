# peer_cra for Stata

`peer_cra` estimates endogenous peer effects under conditional random
assignment to peer groups within urns, or selection pools. It implements a
two-step GMM estimator with optional own-effect and peer-effect covariates and a
heteroskedasticity-robust, bias-corrected covariance estimator.

The command requires Stata 16 or newer.

## Installation

### Use a local clone

Clone or download this repository, then add its `ado` and `help` directories to
the Stata search path:

```stata
adopath + "/full/path/to/peergmm-stata/ado"
adopath + "/full/path/to/peergmm-stata/help"
mata: mata mlib index
```

Check the installation with:

```stata
which peer_cra
help peer_cra
```

### Install in Stata's personal ado directory

Run `sysdir` in Stata to locate the `PERSONAL` directory. Copy these five files
into that directory:

```text
ado/peer_cra.ado
ado/peer_cra_p.ado
ado/lpeergmm.mlib
ado/lpeergmm.mata
help/peer_cra.sthlp
```

The compiled Mata library is the normal fast path. If it was compiled by a
newer Stata release and cannot be loaded, `peer_cra` compiles the shipped
`lpeergmm.mata` source in the current Stata session.

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

matrix list e(b)
matrix list e(V)

predict double yhat, fitted
predict double resid, residuals
predict double urn_fe, alpha
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

- `ado/peer_cra.ado`: estimation command.
- `ado/peer_cra_p.ado`: postestimation `predict` command.
- `ado/lpeergmm.mlib`: compiled Mata library.
- `help/peer_cra.sthlp`: Stata help file.

Keep all four files in `ado/` together. 

## Companion R package

The companion R implementation is available at
[zengying17/peergmm-r](https://github.com/zengying17/peergmm-r).

## Citation

Ying Zeng, *Estimation and Inference for Peer Effects under Conditional Random
Assignment*. Citation details will be updated when the paper is released.
