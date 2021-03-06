# Mylogger Add-on Demo

This is an example implementation of a Heroku Partner Add-on. More specifically, this add-on lets you persist the log messages
generated by the Heroku application where it's installed. It isn't meant to be useful at all, due to its obvious limitations, but
is a good way to exercise using Heroku's Add-on Partner API and best practices.

## Prerequisites

* Log in or sign up for a free Heroku account at [heroku.com](https://heroku.com).
* Register as an add-on partner on the [Add-on Partner Portal](https://addons-next.heroku.com/).
* Install Heroku's CLI (command line interface tool), if you haven't done that already, following the
  [instructions](https://devcenter.heroku.com/articles/heroku-cli#download-and-install) for your platform.
* [Log in](https://devcenter.heroku.com/articles/heroku-cli#getting-started) with the CLI tool and install
  the Add-ons Admin plug-in by following these
  [instructions](https://github.com/heroku/heroku-cli-addons-admin#installation).

## Implementation

Implementation was done through various iterations, by following Heroku's Devcenter documentation on
[Building an Add-on](https://devcenter.heroku.com/articles/building-an-add-on).

### Generating the JSON manifest

I generated the initial manifest as explained
[here](https://devcenter.heroku.com/articles/building-an-add-on#step-1-generate-your-add-on-manifest) and made all the
required changes before [pushing it](https://github.com/heroku/heroku-cli-addons-admin#heroku-addonsadminmanifestpush)
to the Add-on Partner Portal.

My final `addon-manifest.json` file contents were roughly as follows (obviously, I won't put here the sensitive info):

```json
{
  "id": "mylogger-demo",
  "api": {
    "regions": [
      "us"
    ],
    "version": "3",
    "password": "scrubbed password",
    "requires": [
      "syslog_drain"
    ],
    "sso_salt": "scrubbed sso_salt",
    "production": {
      "sso_url": "https://mylogger-addon.herokuapp.com/sso/login",
      "base_url": "https://mylogger-addon.herokuapp.com/heroku/resources"
    },
    "config_vars": [
      "MYLOGGER_DEMO_URL"
    ],
    "config_vars_prefix": "MYLOGGER_DEMO"
  },
  "name": "My Logger Addon Demo",
  "$base": 11111111111111
}
```

> Note: you can't use the words _add-on_ or _addon_ as part of the `id` (aka _slug_) to identify your add-on.
> Be smarter than me.

### Integrating with the Add-on Partner API

Each add-on must provide correctly implemented endpoints for _provisioning_, _deprovisioning_ and _changing plans_.
For this demo I haven't implemented the plan change endpoint as it will never reach GA release stage and there's only a
[free _test_ plan](https://devcenter.heroku.com/articles/bringing-an-add-on-to-market#alpha-stage) allowed, but it's a __MUST__
for a real add-on if it will be offering different plans.

#### The provisioning request

Heroku uses the name _resource_ to identify a provisioned add-on for an application, so it was natural to use the same name here
to model that domain object. Each instance of the
[`Resource`](app/models/resource.rb) model class represents a provisioning
of this Add-on on some Heroku application.

The life cycle of each one of these resources is controlled by a finite state machine defined in the model class using the
[state_machines](https://github.com/state-machines/state_machines) gem.

![State machine diagram](public/doc/state_machines/Resource_state.png)

Provisioning endpoint must respond to `POST` requests sent to the `base_url` defined in the add-on manifest. This is implemented
through Rails routing (in [`config/routes.rb`](config/routes.rb)) as follows:

```ruby
# Heroku's resource provisioning and deprovisioning endpoints
namespace :heroku do
  resources :resources, only: %i[create destroy],
                        constraints: ->(req) { req.headers["Accept"] == Heroku::MimeType::ADDON_PARTNER_API }
  match "*path" => "errors#not_found", :via => :all
end
```

Constraints are applied to the matching endpoint to ensure it's a valid request from the specific Heroku Add-on Partner API
version implemented. Any other request is redirected to a controller that returns a valid response body with a meaningful error
indication as suggested [here](https://devcenter.heroku.com/articles/add-on-partner-api-reference#exceptions).

A valid request to the provisioning endpoint sends credentials to perform HTTP basic authentication. Heroku uses
the `id` as user name combined with the `password` to authenticate (both values are defined in the add-on manifest).
The private method `authenticate!` at
[`Heroku::ResourcesController`](app/controllers/heroku/resources_controller.rb)
handles the authentication.

Once the request passes the authentication, the `create` action will create a new
[`Resource`](app/models/resource.rb) instance with the provided params
and send the `provision` event to it. This event will trigger a callback that enqueues a
[`Heroku::ProvisioningJob`](app/jobs/heroku/provisioning_job.rb) to
perform an
[_asynchronous provisioning_](https://devcenter.heroku.com/articles/add-on-partner-api-reference#asynchronous-provisioning).
The `create` action finalizes by returning a _202 Accepted_ status code as required for asynchronous provisioning.

[`Heroku::ProvisioningJob`](app/jobs/heroku/provisioning_job.rb) will be picked
up in the background by the `ActiveJob` handler (in this case I'm using [DelayedJob](https://github.com/collectiveidea/delayed_job))
which makes a call to the
[`Heroku::ProvisioningManager::ResourceProvisioner`](app/services/heroku/provisioning_manager/resource_provisioner.rb)
service object and check the result, raising an exception to force retrying in case of failure.

[`Heroku::ProvisioningManager::ResourceProvisioner`](app/services/heroku/provisioning_manager/resource_provisioner.rb)
is an orchestrator service object in charge of sequentially calling other three service objects who implement each one of the
asynchronous provisioning steps:

* [OAuth Grant Code Exchange](https://devcenter.heroku.com/articles/add-on-partner-api-reference#grant-code-exchange)
  is performed by the [`Heroku::AuthorizationManager::GrantExchanger`](app/services/heroku/authorization_manager/grant_exchanger.rb) service object.
* Provisioning of the necessary resources in the infrastructure is simulated by the
  [`Heroku::ProvisioningManager::ResourceAllocator`](app/services/heroku/provisioning_manager/resource_provisioner.rb)
  service object. In this demo add-on it doesn't allocates any physical resources, but in a real add-on it should implement all
  required steps to allocate resources (creating databases, configuring disk quotas, etc.).
* [Add-on Config Update](https://devcenter.heroku.com/articles/add-on-partner-api-reference#add-on-config-update)
  is performed by the
  [`Heroku::ProvisioningManager::AddonConfigUpdater`](app/services/heroku/provisioning_manager/addon_config_updater.rb)
  service object. Here, we only use it to
  [mark the add-on as successfully provisioned](https://devcenter.heroku.com/articles/add-on-partner-api-reference#add-on-action-create-provision),
  but a real add-on might require to implement the update of some config vars before marking the add-on as ready to be used.

A fourth service object, namely
[`Heroku::AuthorizationManager::TokenRefresher`](app/services/heroku/authorization_manager/token_refresher.rb),
is used when required to
[refresh an expired OAuth access token](https://devcenter.heroku.com/articles/add-on-partner-api-reference#access-token-refresh).

#### The deprovisioning request

In a similar way to provisioning, the `destroy` action from
[`Heroku::ResourcesController`](app/controllers/heroku/resources_controller.rb)
handles a deprovisioning request. After successful authentication it will just send the `deprovision` event to the targeted
resource (provided it exists), and return a _204 No content_ status code.

The `deprovision` event will trigger a callback that enqueues a
[`Heroku::DerovisioningJob`](app/jobs/heroku/provisioning_job.rb) which will run in the
background and make a call to the
[`Heroku::ProvisioningManager::ResourceDeprovisioner`](app/services/heroku/provisioning_manager/resource_deprovisioner.rb
) service object. As this demo add-on persists the log messages from the application where it's installed, this service object only
takes care of deleting all log frames stored for the resource.

#### Deploy the add-on

This last step requires the deploy of the application to a publicly accessible hosting service. I have obviously used Heroku for
that. The running version of this add-on can be found at [https://mylogger-addon.herokuapp.com/](https://mylogger-addon.herokuapp.com/). There's nothing to see there,
because you need to access that site from a Heroku application where the add-on is installed, sorry for the inconvenience if you
clicked that link from this README.

Finally, the `addon-manifest.json` file has to be
[pushed](https://devcenter.heroku.com/articles/building-an-add-on#step-3-deploy-the-add-on) to Heroku in order for the add-on
to become available. Remember that pushing the manifest will register the Add-on in
[_Alpha_ stage](https://devcenter.heroku.com/articles/bringing-an-add-on-to-market#alpha-stage),
so you can only install it on an application by being invited and through the CLI tool.

### Logging add-ons (or how to make this add-on something roughly useful)

At this point I had an add-on that successfully provisioned and deprovisioned resources, but it was way too far from being useful
at all.

For a real life add-on you would have an idea of what service you're going to provide to the applications of your future customers.
I had no one, and as I'm not that savvy, I just came up with the idea of persisting log messages from the application, which was
fairly easy to do.

If an add-on wishes to receive the application logs it must notify Heroku so that a log drain is created to send log frames
generated by the application to a receiving endpoint exposed publicly. That's accomplished by adding the flag
`syslog_drain` to the `requires` section in the add-on manifest file. When this flag is set an additional parameter named
`log_drain_token` is sent on the original provision request. This is an immutable token that is meant to identify the
log drain in order to associate it with a specific resource. Log frames are sent without any kind of authentication mechanism, so
this token will be used to validate the authenticity of the received log frame, provided that the token is owned by an
active (not deprovisioned) resource.

The URL at which log frames will be received must be supplied to Heroku on a key named `log_drain_url` inside the JSON response
to the provision request. For this demo I'm using the same URL for all resources, and differentiate the targeted resource
by using the log drain token present in the headers when a log frame is posted to that URL. Invalid requests to that URL are
discarded at routing stage by using similar constraints as showed for the provisioning requests.

The `create` method of [`Logplex::LogFramesController`](app/controllers/logplex/log_frames_controller.rb) handles a valid
request made to the log drain URL. Before the action is called parameters present in the headers are extracted and validated,
checking that an active resource is targeted by the log drain token. The targeted resource and log frame data are then handled to
the [`LogFramesManager`](app/services/log_frames_manager.rb) service object to be persisted.

The [`LogFramesManager`](app/services/log_frames_manager.rb) service object has an extra responsibility besides persisting the
log frame received. It ensures the total count of log messages for the targeted resource doesn't exceeds the limit imposed by
the selected plan. It's just a matter of showing how plans can be used to enforce certain restrictions for a particular resource,
as we only can have a free test plan in _Alpha_ stage.

Log frames consist of a set of one or more log messages with a specified format and framing. More information on HTTPS log drains
can be found at [this Devcenter article on HTTPS drains](https://devcenter.heroku.com/articles/log-drains#https-drains). In this
implementation, the whole log frame content is stored encrypted. Individual log messages are represented by the
[`LogMessage`](app/models/log_message.rb) model class, but are not persisted individually. It's just a convenience class used when
parsing the frame contents to ease accessing and validating log message attributes.

### Add-on resource dasboard & SSO login

At this point I had an add-on that could be provisioned and deprovisioned and that also persisted the log messages from the
application where it was installed. But there's no point on doing this unless someone is able to see the log messages, is there?
So, for this to work I had to implement a UI that would show the stored log messages to a user. The UI look and feel was completely
stolen (with its license permission) as I'm nothing of a web designer, that was the easy part. The tricky part is authentication,
as we must ensure that users cannot see log messages from a resource they aren't allowed to access.

This part is tricky because our add-on resources aren't owned by users, but by Heroku applications. Briefly describing the owning
model it can be said that _users own applications_ and _applications own add-ons_. Technically, it's a little more complex than
that, but it will be more than enough for this explanation. So, we can't create user accounts and implement a classic user login
mechanism for people to access the add-on resource stored log messages, as we have no information about the users of the Heroku
application that owns our resource.

Here's when Heroku cames to the rescue and provides us an
[Add-on Single Sign-on](https://devcenter.heroku.com/articles/add-on-single-sign-on) mechanism so that we can authenticate
the user. It's like authenticating by a transitive property. If the user wanting to reach our resource's dashboard has been
already authenticated and authorized by Heroku to access the application that owns our add-on resource, then we are able to
authenticate that user provided the request is received from Heroku on behalf of the user.

Then it's just a matter of validating that the request was originated from Heroku. That's done by reconstructing a token
from information sent to the `sso_url` endpoint we set initially on our add-on manifest and comparing it to the one present in the
request.

The token is a cryptographic hash generated by the [SHA-1 function](https://en.wikipedia.org/wiki/SHA-1) from a string consisting
of three components:

* The resource `id` as established when the resource was first provisioned.
* A secret _salt_ (the value of the `sso_salt` key in our add-on manifest).
* The timestamp at which the token was generated, expressed as [Unix time](https://en.wikipedia.org/wiki/Unix_time).

The component that lets us know it is a valid request originated from Heroku is the _salt_, as it's a secret only known by our
add-on and Heroku. The other two components are sent as URL parameters along with the generated token for us to reconstruct and
compare against the received token.

[`Sso::SessionsController`](app/controllers/sso/sessions_controller.rb) handles log-in requests sent from Heroku and log-out
requests performed by the user. Here, I'm using a simple
[cookie store](https://api.rubyonrails.org/classes/ActionDispatch/Session/CookieStore.html) to hold the session info that
consists basically on saving the internal resource _id_ into the session store.

After a successful log-in, a session is created and the user is redirected to the dashboard URL.

The [`DashboardsController`](app/controllers/dashboards_controller.rb) has only the `show` action implemented and it simply
validates that the user is authenticated and scopes the request to show log messages for the resource linked in the user session
info, provided the resource is still active, as it also scopes to only resources in provisioned state.

![That's all folks!](public/doc/images/thats_all_folks.png)

## Best practices

### TDD

Last, but not least, implementation was done following a [TDD](https://en.wikipedia.org/wiki/Test-driven_development) process,
so there's more than 100 tests to ensure the application behaves as required by Heroku APIs, giving a test coverage greater
than 98% of the code base.

### YARD documentation

Code was documented using [YARD](https://yardoc.org/). A live version of the documents can be found here:
[YARD documentation](https://mylogger-addon.herokuapp.com/doc/index.html).
