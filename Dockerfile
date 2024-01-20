FROM public.ecr.aws/amazonlinux/amazonlinux:2023
RUN dnf update
RUN dnf -y install gcc make git bash libcurl-devel tar

WORKDIR /build/janet
RUN git clone --depth 1 https://github.com/janet-lang/janet.git .
RUN git checkout $COMMIT

RUN make PREFIX=/app -j
RUN make PREFIX=/app install

WORKDIR /build/jpm
RUN git clone --depth 1 https://github.com/janet-lang/jpm .
RUN PREFIX=/app /app/bin/janet bootstrap.janet

ENV PATH="/app/bin:$PATH"
WORKDIR /app

RUN mkdir -p /app/project
COPY project.janet /app/project
WORKDIR /app/project
RUN jpm deps --local

COPY . /app/project/
RUN jpm build --local

RUN mkdir lambda

ARG WITH_SOURCE
WORKDIR /app/project/jpm_tree
RUN if [ -n "$WITH_SOURCE" ]; then zip --exclude lib/.cache/\* -r  ../lambda/lambda.zip lib/ ; fi

WORKDIR /app/project/src
RUN if [ -n "$WITH_SOURCE" ]; then zip -r  ../lambda/lambda.zip . ; fi

WORKDIR /app/project/build
RUN echo "#!/bin/sh" > bootstrap
RUN echo 'export JANET_PATH=$LAMBDA_TASK_ROOT/lib' >> bootstrap
RUN echo 'exec ./runtime' >> bootstrap
RUN chmod +x bootstrap
RUN zip -r  ../lambda/lambda.zip runtime bootstrap

WORKDIR /app/project

CMD ["janet"] 
