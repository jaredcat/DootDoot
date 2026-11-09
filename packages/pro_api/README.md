# pro_api

Pro capability interfaces and the free host for DootDoot open-core.

The public app uses `FreeProController` (1-account cap, no Pro routes, no-op offline cache). The private store build overrides `proControllerProvider` with a proprietary controller.
